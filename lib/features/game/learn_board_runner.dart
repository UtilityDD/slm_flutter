import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/ai_lineman_guide.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../home/lesson_progress_store.dart';
import '../shell/shell_providers.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'beat_fx.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'learn_board_models.dart';
import 'myth_rival_puppet.dart';

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

  late final AnimationController _celebrate;
  late final AnimationController _burn;
  late final AnimationController _rivalEnter;
  late final AnimationController _rivalBob;
  late final AnimationController _rivalExit;
  late final AnimationController _rivalJab;
  late final AnimationController _stageShake;
  late final AnimationController _scorePunch;

  _Beat _beat = _Beat.intro;
  int _slot = 0;
  int _pending = 0;
  int _pendingFxToken = 0;
  final List<String> _worn = [];
  String? _pickedWhy;
  bool _muted = false;

  /// True while a scripted moment plays (feedback, transitions, the rival
  /// cutscene). Choices and mascot taps are ignored; prompts never lock.
  bool _locked = false;
  int _voiceRun = 0;
  var _whyRetry = false;
  var _burning = false;
  int _rivalLayers = 0;
  var _rivalDefeated = false;
  var _rivalOnStage = false;

  /// Rival owns the voice: [MascotTalk] drives his snarl instead of the coach.
  var _rivalVoice = false;
  String _rivalBubbleBn = '';
  var _askReady = false;
  int _rivalLandToken = 0;
  var _tagsShown = false;
  int _cardWave = 0;

  /// Last tapped card: it shakes (wrong) or pops (right) on each new token.
  String? _hitId;
  var _hitGood = false;
  int _hitToken = 0;
  List<LearnBoardOption> _pickOpts = const [];
  List<LearnWhyChip> _whyOpts = const [];

  LearnBoardPack get _pack => widget.pack;
  LearnBoardSlot get _cur => _pack.slots[_slot];

  bool get _missionHero => _beat == _Beat.intro || _beat == _Beat.award || _beat == _Beat.done;

  /// Card boards reserve a top lane for step pips and the pending ◆ chip.
  bool get _boardBeat => _beat == _Beat.pick || _beat == _Beat.why || _beat == _Beat.mythWhy;

  static const _laneHeight = 56.0;

  @override
  void initState() {
    super.initState();
    _muted = widget.muted;
    _celebrate = AnimationController(vsync: this, duration: const Duration(milliseconds: 920));
    _burn = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
    _rivalEnter = AnimationController(vsync: this, duration: _rivalEnterTime);
    // Loops only while the rival is on stage (started/stopped in the cutscene).
    _rivalBob = AnimationController(vsync: this, duration: const Duration(milliseconds: 920));
    _rivalExit = AnimationController(vsync: this, duration: const Duration(milliseconds: 720));
    _rivalJab = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _stageShake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _scorePunch = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
    _burn.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _burning = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_startIntro());
    });
  }

  @override
  void dispose() {
    _voiceRun++;
    unawaited(MascotSpeechLibrary.stop());
    _celebrate.dispose();
    _burn.dispose();
    _rivalEnter.dispose();
    _rivalBob.dispose();
    _rivalExit.dispose();
    _rivalJab.dispose();
    _stageShake.dispose();
    _scorePunch.dispose();
    super.dispose();
  }

  String _promptForBeat() {
    return switch (_beat) {
      _Beat.intro => _pack.introBn,
      _Beat.pick => 'সঠিক জিনিস বেছে নিন',
      _Beat.why => 'কেন এটা ঠিক?',
      _Beat.mythSay => '',
      _Beat.mythBelieve => _pack.myth.stingBn,
      _Beat.mythWhy => 'কেন বিশ্বাস করবেন না?',
      _Beat.award || _Beat.done => '${_pack.badgeBn} পেয়েছেন।',
    };
  }

  Future<void> _onMascotTap() async {
    if (_locked) return;
    final line = _promptForBeat().trim();
    if (line.isEmpty) return;
    HapticFeedback.selectionClick();
    if (!_muted) {
      unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    }
    await _say(line, mood: GuideMood.talk);
  }

  static const _rivalEnterTime = Duration(milliseconds: 760);

  /// Fraction of [_rivalEnterTime] at which his boots hit the floor.
  static const _rivalLandAt = 0.72;

  /// One flick per card, fired by the card itself as it leaves the deck.
  void _dealCue(int i) {
    if (_muted) return;
    final file = i.isEven ? 'sounds/learn/card_deal_a.wav' : 'sounds/learn/card_deal_b.wav';
    unawaited(ZlFx.cue(file, volume: 0.62, muted: false));
  }

  void _markHit(String id, bool good) {
    setState(() {
      _hitId = id;
      _hitGood = good;
      _hitToken++;
    });
  }

  int _hitFor(String id) => _hitId == id ? _hitToken : 0;

  Future<void> _stopVoice() async {
    _voiceRun++;
    await MascotSpeechLibrary.stop();
  }

  /// Time a player needs to read [line] in the bubble (also the floor when the
  /// voice is muted or fails, so beats never collapse to zero length).
  Duration _readTime(String line) {
    final ms = (700 + line.trim().length * 48).clamp(1100, 3800);
    return Duration(milliseconds: ms);
  }

  /// Coach line: bubble + voice + lips. Completes when the line has been heard
  /// (or read, when muted). Returns false if a newer line interrupted it.
  Future<bool> _say(String line, {GuideMood mood = GuideMood.talk}) async {
    if (line.trim().isEmpty) return true;
    ref.read(guideDirectorProvider.notifier).say(mood: mood, line: line);
    return _voiceLine(line, rival: false);
  }

  /// Rival line: his bubble + his gruff voice; the coach stays silent.
  Future<bool> _rivalSay(String line) async {
    _rivalJab.forward(from: 0);
    setState(() {
      _rivalBubbleBn = line;
      _rivalVoice = true;
    });
    final heard = await _voiceLine(line, rival: true);
    if (mounted) setState(() => _rivalVoice = false);
    return heard;
  }

  Future<bool> _voiceLine(String line, {required bool rival}) async {
    final run = ++_voiceRun;
    final clock = Stopwatch()..start();
    await MascotSpeechLibrary.speak(
      line,
      muted: _muted,
      pitch: rival ? 0.78 : 1.0,
      rate: rival ? 0.56 : 0.48,
    );
    if (!mounted) return false;
    // Muting mid-line still leaves the bubble up long enough to read.
    final floor = (_muted || run != _voiceRun) ? _readTime(line) : _readTime(line) * 0.55;
    final rest = floor - clock.elapsed;
    if (rest > Duration.zero) await Future<void>.delayed(rest);
    return mounted && run == _voiceRun;
  }

  /// Small breath between beats so scenes read as separate moments.
  Future<bool> _pause(int ms) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
    return mounted;
  }

  Offset _pendingOrigin() {
    final box = _pendingDockKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
    }
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width * 0.82, size.height * 0.18);
  }

  /// Runs a scripted moment with input locked. Prompts that follow should be
  /// spoken after this returns so the player can answer while they play.
  Future<void> _scripted(Future<void> Function() body) async {
    _locked = true;
    try {
      await body();
    } finally {
      _locked = false;
    }
  }

  Future<void> _startIntro() async {
    setState(() => _beat = _Beat.intro);
    await _scripted(() async {
      if (!await _pause(420)) return;
      await _say(_pack.introBn, mood: GuideMood.inspire);
      await _pause(320);
    });
    if (!mounted) return;
    await _enterSlot(0);
  }

  Future<void> _enterSlot(int i) async {
    await _stopVoice();
    if (!mounted) return;
    final opts = [...widget.pack.slots[i].options]..shuffle(math.Random(i * 31 + 17));
    setState(() {
      _slot = i;
      _beat = _Beat.pick;
      _pending = 0;
      _pickedWhy = null;
      _whyRetry = false;
      _burning = false;
      _pickOpts = opts;
      _hitId = null;
      _cardWave++;
    });
    await _say('সঠিক জিনিস বেছে নিন', mood: GuideMood.talk);
  }

  Future<void> _onPick(LearnBoardOption opt, Offset global) async {
    if (_beat != _Beat.pick || _locked) return;
    _markHit(opt.id, opt.correct);
    await _stopVoice();
    if (!opt.correct) {
      HapticFeedback.mediumImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.72, muted: false));
      ref.read(guideDirectorProvider.notifier).react(GuideMood.warn);
      await _say(
        opt.rejectBn.isNotEmpty ? opt.rejectBn : 'এটা নয়। সঠিক জিনিস বেছে নিন।',
        mood: GuideMood.warn,
      );
      return;
    }

    final why = [..._cur.whyChips]..shuffle(math.Random(_slot * 19 + 5));
    await _scripted(() async {
      HapticFeedback.lightImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.78, muted: false));
      setState(() {
        _pending = _cur.pendingPoints;
        _pendingFxToken++;
        if (_cur.wearAsset.isNotEmpty && !_worn.contains(_cur.wearAsset)) {
          _worn.add(_cur.wearAsset);
        }
      });
      _celebrate.forward(from: 0);
      _scorePunch.forward(from: 0);
      // Let the picked card's pop read before the board changes.
      if (!await _pause(460)) return;
      setState(() {
        _beat = _Beat.why;
        _pickedWhy = null;
        _hitId = null;
        _whyOpts = why;
        _cardWave++;
      });
      await _pause(320);
    });
    if (!mounted) return;
    await _say('কেন এটা ঠিক?', mood: GuideMood.inspire);
  }

  Future<void> _bankPending(int bank, Offset global) async {
    if (bank <= 0) return;
    final origin = _pending > 0 ? _pendingOrigin() : global;
    setState(() => _pending = 0);
    _celebrate.forward(from: 0);
    _scorePunch.forward(from: 0);
    if (!_muted) {
      unawaited(ZlFx.cue('sounds/intro/confirm.ogg', volume: 0.7, muted: false));
    }
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
    if (_beat != _Beat.why || _locked) return;
    await _stopVoice();
    setState(() => _pickedWhy = chip.id);
    _markHit(chip.id, chip.correct);

    if (!chip.correct) {
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.72, muted: false));
      await _burnPending();
      ref.read(guideDirectorProvider.notifier).react(GuideMood.warn);
      await _say('এই কারণ নয়। আবার বেছে নিন।', mood: GuideMood.warn);
      return;
    }

    await _scripted(() async {
      final bank = _pending > 0 ? _pending : (_whyRetry ? 5 : 0);
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.8, muted: false));
      await _bankPending(bank, global);
      await _say('ঠিক।', mood: GuideMood.glad);
      await _pause(240);
    });
    if (!mounted) return;
    if (_slot < _pack.slots.length - 1) {
      await _enterSlot(_slot + 1);
    } else {
      await _enterMyth();
    }
  }

  /// Myth cutscene: coach warns → rival storms in, taunts, claims, gets tagged
  /// with dangers, sneers and leaves → coach returns and asks. Input is locked
  /// until the question has been asked.
  Future<void> _enterMyth() async {
    await _stopVoice();
    if (!mounted) return;
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final myth = _pack.myth;
    await _scripted(() async {
      setState(() {
        _beat = _Beat.mythSay;
        _pending = 0;
        _pickedWhy = null;
        _whyRetry = false;
        _burning = false;
        _rivalLayers = 0;
        _tagsShown = false;
        _rivalBubbleBn = '';
        _rivalDefeated = false;
        _rivalOnStage = false;
        _rivalVoice = false;
        _askReady = false;
      });
      _rivalExit.value = 0;
      _rivalEnter.value = 0;
      if (!await _pause(360)) return;
      await _say('সাবধান! একজন অসাবধান লাইনম্যান আসছে…', mood: GuideMood.warn);
      if (!mounted) return;

      // Rival rushes in from the right and stomps down.
      ref.read(guideDirectorProvider.notifier).clearLine();
      setState(() => _rivalOnStage = true);
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_in.wav', volume: 0.75, muted: false));
      if (quiet) {
        _rivalEnter.value = 1;
        _rivalLand();
      } else {
        _rivalBob.repeat(reverse: true);
        final landIn = _rivalEnterTime * _rivalLandAt;
        Future<void>.delayed(landIn, () {
          if (mounted && _rivalOnStage) _rivalLand();
        });
        await _rivalEnter.forward(from: 0);
      }
      if (!await _pause(260)) return;

      await _rivalSay(myth.tauntBn);
      if (!await _pause(180)) return;
      await _rivalSay(myth.rivalLineBn);
      if (!mounted) return;

      // Slap a warning tag on each bad bit, one beat at a time.
      setState(() {
        _rivalBubbleBn = '';
        _tagsShown = true;
      });
      for (var i = 0; i < myth.dangerHints.length; i++) {
        if (!await _pause(i == 0 ? 300 : 520)) return;
        HapticFeedback.mediumImpact();
        if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.7, muted: false));
        setState(() => _rivalLayers = i + 1);
      }
      if (!await _pause(1100)) return;

      setState(() => _tagsShown = false);
      await _rivalSay(myth.exitBn);
      if (!mounted) return;
      setState(() => _rivalBubbleBn = '');
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_out.wav', volume: 0.7, muted: false));
      if (quiet) {
        _rivalExit.value = 1;
      } else {
        await _rivalExit.forward(from: 0);
      }
      if (!mounted) return;
      _rivalBob.stop();

      // Coach reclaims the stage, then asks.
      setState(() {
        _rivalOnStage = false;
        _beat = _Beat.mythBelieve;
      });
      if (!await _pause(380)) return;
      await _say(myth.stingBn, mood: GuideMood.inspire);
      if (!mounted) return;
      setState(() => _askReady = true);
    });
  }

  /// Boots hit the floor: thud, rumble, dust.
  void _rivalLand() {
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/stomp.wav', volume: 0.9, muted: false));
    _stageShake.forward(from: 0);
    setState(() => _rivalLandToken++);
  }

  Future<void> _onBelieve(bool yes, Offset global) async {
    if (_beat != _Beat.mythBelieve || _locked || !_askReady) return;
    await _stopVoice();
    final correct = _pack.myth.believeNoIsCorrect ? !yes : yes;
    final why = [..._pack.myth.whyChips]..shuffle(math.Random(correct ? 77 : 88));
    if (correct) {
      await _scripted(() async {
        setState(() {
          _rivalDefeated = true;
          _pending = _pack.myth.pendingPoints;
          _pendingFxToken++;
          _whyOpts = why;
          _cardWave++;
        });
        _celebrate.forward(from: 0);
        _scorePunch.forward(from: 0);
        if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.78, muted: false));
        HapticFeedback.lightImpact();
        await _say('ঠিক ধরেছেন।', mood: GuideMood.glad);
        if (!mounted) return;
        setState(() {
          _beat = _Beat.mythWhy;
          _hitId = null;
        });
        await _pause(320);
      });
      if (!mounted) return;
      await _say('কেন বিশ্বাস করবেন না?', mood: GuideMood.inspire);
      return;
    }

    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.78, muted: false));
    setState(() {
      _whyRetry = true;
      _whyOpts = why;
      _cardWave++;
    });
    await _burnPending();
    if (!mounted) return;
    setState(() {
      _beat = _Beat.mythWhy;
      _hitId = null;
    });
    await _say('ভুল বিশ্বাস। কেন নয়, বলুন।', mood: GuideMood.warn);
  }

  Future<void> _onMythWhy(LearnWhyChip chip, Offset global) async {
    if (_beat != _Beat.mythWhy || _locked) return;
    await _stopVoice();
    setState(() => _pickedWhy = chip.id);
    _markHit(chip.id, chip.correct);
    if (!chip.correct) {
      await _burnPending();
      await _say('আবার ভাবুন।', mood: GuideMood.warn);
      return;
    }
    await _scripted(() async {
      final bank = _pending > 0 ? _pending : (_whyRetry ? 5 : 0);
      await _bankPending(bank, global);
      await _say('এই তো আসল কথা।', mood: GuideMood.celebrate);
      if (!await _pause(260)) return;
      await _award();
    });
  }

  Future<void> _award() async {
    await _stopVoice();
    if (!mounted) return;
    setState(() => _beat = _Beat.award);
    final save = ref.read(gameSaveProvider.notifier);
    final already = ref.read(gameSaveProvider).rungProgress[widget.rungId] == 'cleared';
    await save.markRungCleared(widget.rungId);
    final bonus = already ? 5 : _pack.clearBonus;
    if (!await _pause(420) || !mounted) return;
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
    if (!mounted) return;
    await _say('${_pack.badgeBn} পেয়েছেন। এবার আসল পোশাক পরান।', mood: GuideMood.celebrate);
    if (!mounted) return;
    setState(() => _beat = _Beat.done);
    if (!await _pause(1100) || !mounted) return;
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

  Color _washFor(_Beat beat) {
    // Ladder-consistent midnight navy; myth leans danger, award leans gold.
    return switch (beat) {
      _Beat.mythSay || _Beat.mythBelieve || _Beat.mythWhy => const Color(0xFF140810),
      _Beat.award || _Beat.done => const Color(0xFF141008),
      _Beat.why => SlmColors.navy900,
      _ => SlmColors.navy950,
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
                backgroundColor: SlmColors.navy950,
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
                                _washFor(_beat),
                                SlmColors.navy950,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: SlmBackground(constrain: false, child: const SizedBox.expand()),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: _beat == _Beat.intro
                                    ? const Alignment(0, -0.15)
                                    : const Alignment(-0.55, 0.75),
                                radius: 1.1,
                                colors: [
                                  palette.accent.withValues(alpha: 0.06),
                                  Colors.transparent,
                                ],
                              ),
                            ),
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
                                  if (_boardBeat) _stepPips(palette),
                                  if (_pending > 0 || _burning) _pendingDock(quiet, palette),
                                  // Corner coach steps aside while the rival owns the
                                  // stage, and while he stands center to ask.
                                  if (!_missionHero && !_rivalOnStage && _beat != _Beat.mythBelieve)
                                    Positioned(
                                      left: 4,
                                      bottom: 4,
                                      child: AiLinemanGuide(
                                        sprite: 148,
                                        bubbleWidth: 210,
                                        showBubble: true,
                                        large: true,
                                        centered: false,
                                        onTap: () => unawaited(_onMascotTap()),
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
          _Beat.why => _whyBoard(_whyOpts, _onWhy, palette, quiet),
          _Beat.mythSay || _Beat.mythBelieve => _rivalEncounter(palette, quiet),
          _Beat.mythWhy => _whyBoard(_whyOpts, _onMythWhy, palette, quiet),
          _Beat.award || _Beat.done => _awardStage(palette, quiet),
        },
      ),
    );
  }

  Widget _missionStage(SlmPalette palette, bool quiet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          SlmReveal(
            index: 0,
            child: Text(
              enDigits(_pack.badgeBn),
              textAlign: TextAlign.center,
              style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.gold300),
            ),
          ),
          const Spacer(flex: 1),
          SlmReveal(
            index: 1,
            rise: 22,
            child: AiLinemanGuide(
              sprite: 196,
              bubbleWidth: 280,
              showBubble: true,
              large: true,
              centered: true,
              onTap: () => unawaited(_onMascotTap()),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _pickBoard(SlmPalette palette, bool quiet) {
    final opts = _pickOpts.isEmpty ? _cur.options : _pickOpts;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, _laneHeight, 14, 168),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.9,
              ),
              itemCount: opts.length,
              itemBuilder: (_, i) {
                final o = opts[i];
                return _AnimatedChoiceCard(
                  key: ValueKey('pick-$_cardWave-${o.id}'),
                  index: i,
                  quiet: quiet,
                  style: _DealStyle.deal,
                  hitToken: _hitFor(o.id),
                  hitGood: _hitGood,
                  onLaunch: () => _dealCue(i),
                  child: _optionTile(
                    asset: o.asset,
                    label: o.labelBn,
                    palette: palette,
                    onTapDown: (d) {
                      if (!_muted) {
                        unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.55, muted: false));
                      }
                      _onPick(o, d.globalPosition);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _whyBoard(
    List<LearnWhyChip> chips,
    Future<void> Function(LearnWhyChip, Offset) onPick,
    SlmPalette palette,
    bool quiet,
  ) {
    final list = chips;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, _laneHeight, 16, 168),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              clipBehavior: Clip.none,
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final c = list[i];
                final hot = _pickedWhy == c.id;
                return _AnimatedChoiceCard(
                  key: ValueKey('why-$_cardWave-${c.id}'),
                  index: i,
                  quiet: quiet,
                  style: _DealStyle.slide,
                  hitToken: _hitFor(c.id),
                  hitGood: _hitGood,
                  onLaunch: () => _dealCue(i),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTapDown: (d) {
                        if (!_muted) {
                          unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.55, muted: false));
                        }
                        onPick(c, d.globalPosition);
                      },
                      child: AnimatedContainer(
                        duration: quiet ? Duration.zero : SlmMotion.fast,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: hot
                                ? (c.correct
                                    ? [
                                        SlmColors.emerald500.withValues(alpha: 0.32),
                                        SlmColors.navy800,
                                      ]
                                    : [
                                        SlmColors.danger.withValues(alpha: 0.32),
                                        SlmColors.navy800,
                                      ])
                                : [
                                    SlmColors.navy800,
                                    SlmColors.navy900,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hot
                                ? (c.correct ? SlmColors.emerald400 : SlmColors.danger)
                                : SlmColors.gold400.withValues(alpha: 0.45),
                            width: hot ? 1.8 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: SlmColors.gold400.withValues(alpha: hot ? 0.28 : 0.12),
                              blurRadius: hot ? 22 : 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: SlmColors.navy950.withValues(alpha: 0.7),
                                border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.7)),
                              ),
                              child: Text(
                                enDigits('${i + 1}'),
                                style: bangla(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: SlmColors.gold200,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                enDigits(c.textBn),
                                textAlign: TextAlign.left,
                                style: bangla(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                  color: SlmColors.ivory,
                                ),
                              ),
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
        ],
      ),
    );
  }

  Widget _rivalEncounter(SlmPalette palette, bool quiet) {
    final believe = _beat == _Beat.mythBelieve;
    final Widget scene;
    if (_rivalOnStage) {
      // Bubble lane sits above him and never moves with his body, so lines
      // stay readable while he lunges.
      final stage = Column(
        children: [
          SizedBox(
            height: 150,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: quiet ? Duration.zero : const Duration(milliseconds: 280),
                reverseDuration: quiet ? Duration.zero : const Duration(milliseconds: 160),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.72, end: 1).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                ),
                child: _rivalBubbleBn.isEmpty
                    ? const SizedBox.shrink(key: ValueKey('rival-quiet'))
                    : _rivalMythBubble(palette),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: _rivalStage(palette, quiet),
            ),
          ),
        ],
      );
      scene = quiet
          ? stage
          : AnimatedBuilder(
              animation: _stageShake,
              child: stage,
              builder: (_, child) {
                final s = _stageShake.value;
                final fade = 1 - s;
                return Transform.translate(
                  offset: Offset(
                    math.sin(s * math.pi * 9) * 8 * fade,
                    math.cos(s * math.pi * 7) * 4 * fade,
                  ),
                  child: child,
                );
              },
            );
    } else if (believe) {
      // Rival gone: coach steps to center for the belief ask.
      scene = Align(
        alignment: Alignment.bottomCenter,
        child: SlmReveal(
          index: 0,
          rise: 18,
          child: AiLinemanGuide(
            sprite: 168,
            bubbleWidth: 240,
            showBubble: true,
            large: true,
            centered: true,
            onTap: () => unawaited(_onMascotTap()),
          ),
        ),
      );
    } else {
      scene = const SizedBox.expand();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      child: Column(
        children: [
          Expanded(child: scene),
          if (believe && !_rivalDefeated && _askReady) ...[
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

  static const _rivalBox = Size(340, 300);
  static const _rivalSize = 210.0;

  /// Rival on his spot, with dust on landing and the warning tags around him.
  Widget _rivalStage(SlmPalette palette, bool quiet) {
    final hints = _pack.myth.dangerHints;
    return SizedBox(
      width: _rivalBox.width,
      height: _rivalBox.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Danger spotlight behind him (static).
          Positioned(
            left: 40,
            right: 40,
            top: 10,
            bottom: 0,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.25),
                    radius: 0.75,
                    colors: [
                      palette.danger.withValues(alpha: 0.30),
                      palette.danger.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: _rivalBody(quiet)),
          if (!quiet)
            Positioned(
              left: 0,
              right: 0,
              bottom: -20,
              height: 90,
              child: IgnorePointer(
                child: SlmSparkBurst(
                  trigger: _rivalLandToken,
                  radius: 120,
                  count: 18,
                  colors: const [
                    Color(0xFFB8A58C),
                    Color(0xFF8C7B66),
                    Color(0xFFD6C7B0),
                    Color(0xFFFF8A65),
                  ],
                ),
              ),
            ),
          for (var i = 0; i < hints.length && i < _rivalLayers; i++)
            _dangerCallout(i, hints[i], palette, quiet),
        ],
      ),
    );
  }

  /// Rush in (lean + stretch) → stomp squash → idle bob with a lunge per line
  /// → turn on the spot → storm off. Only this subtree rebuilds per frame.
  Widget _rivalBody(bool quiet) {
    final myth = _pack.myth;
    if (quiet) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: MythRivalPuppet(
          size: _rivalSize,
          bodyAsset: myth.bodyAsset,
          phase: 0,
          speaking: false,
          reduce: true,
        ),
      );
    }
    return AnimatedBuilder(
      animation: Listenable.merge([_rivalEnter, _rivalBob, _rivalExit, _rivalJab]),
      builder: (_, _) {
        final e = _rivalEnter.value;
        final x = _rivalExit.value;
        final travel = Curves.easeOutCubic.transform((e / _rivalLandAt).clamp(0.0, 1.0));
        final rush = 1 - travel;
        final land = e < _rivalLandAt ? 0.0 : (e - _rivalLandAt) / (1 - _rivalLandAt);
        final squash = math.sin(land * math.pi) * 0.13 * (1 - 0.4 * land);

        final turn = Curves.easeInOutCubic.transform((x / 0.32).clamp(0.0, 1.0));
        final dash = Curves.easeInCubic.transform(((x - 0.26) / 0.74).clamp(0.0, 1.0));
        final facing = 1 - 2 * turn;

        final jab = math.sin(_rivalJab.value * math.pi);
        final bobT = _rivalBob.value * math.pi * 2;
        final bob = math.sin(bobT) * 4.0;

        final dx = rush * 430 + dash * 470 - jab * 12;
        final dy = bob - rush * 26 + squash * 10 - jab * 4;
        final angle = -0.24 * rush + 0.20 * dash - 0.07 * jab + math.sin(bobT * 0.5) * 0.03;
        final sx = (1 + 0.10 * rush + 0.65 * squash + 0.05 * jab) * facing;
        final sy = 1 - 0.06 * rush - squash + 0.04 * jab;
        final alpha = ((e * 5).clamp(0.0, 1.0) * (1 - dash)).clamp(0.0, 1.0);

        return Opacity(
          opacity: alpha,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // Floor shadow stays on the ground while he bobs.
                Positioned(
                  bottom: 2,
                  child: Container(
                    width: 120 * (1 + squash * 1.6 + 0.06 * jab),
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: RadialGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.rotate(
                    angle: angle,
                    alignment: Alignment.bottomCenter,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values(sx, sy, 1),
                      child: MythRivalPuppet(
                        size: _rivalSize,
                        bodyAsset: myth.bodyAsset,
                        phase: _rivalBob.value,
                        speaking: _rivalVoice && MascotTalk.active.value,
                        reduce: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tag i points at the matching body part: helmet, hands, feet.
  Widget _dangerCallout(int i, String text, SlmPalette palette, bool quiet) {
    const tops = [44.0, 150.0, 246.0];
    final left = i.isEven;
    final top = i < tops.length ? tops[i] : 44.0 + i * 96;
    final tag = Container(
      constraints: const BoxConstraints(maxWidth: 128),
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A0D12), Color(0xFF1C070A)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.danger, width: 1.4),
        boxShadow: [
          BoxShadow(color: palette.danger.withValues(alpha: 0.35), blurRadius: 12),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: palette.danger, shape: BoxShape.circle),
            child: const Text(
              '!',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              enDigits(text),
              style: bangla(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: SoftDanger.ink,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
    final tilt = left ? -0.05 : 0.05;
    return Positioned(
      top: top,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: AnimatedOpacity(
        opacity: _tagsShown ? 1 : 0,
        duration: quiet ? Duration.zero : const Duration(milliseconds: 220),
        child: quiet
            ? Transform.rotate(angle: tilt, child: tag)
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutBack,
                child: tag,
                builder: (_, t, child) => Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: tilt + (1 - t) * (left ? -0.35 : 0.35),
                    child: Transform.scale(scale: 1.7 - 0.7 * t, child: child),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _rivalMythBubble(SlmPalette palette) {
    return ConstrainedBox(
      key: ValueKey(_rivalBubbleBn),
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3B0C14), Color(0xFF22070C)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.danger, width: 1.8),
              boxShadow: [
                BoxShadow(color: palette.danger.withValues(alpha: 0.40), blurRadius: 20, spreadRadius: 1),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.danger,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'অসাবধান লাইনম্যান',
                    style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  enDigits(_rivalBubbleBn),
                  textAlign: TextAlign.center,
                  style: bangla(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    color: SlmColors.ivory,
                  ),
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(26, 14),
            painter: _BubbleTailPainter(
              fill: const Color(0xFF22070C),
              stroke: palette.danger,
            ),
          ),
        ],
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
          const SizedBox(height: 20),
          AiLinemanGuide(
            sprite: 168,
            bubbleWidth: 220,
            showBubble: true,
            large: true,
            centered: true,
            onTap: () => unawaited(_onMascotTap()),
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
            border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.55), width: 1.35),
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
                Expanded(
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    cacheWidth: (MediaQuery.sizeOf(context).width *
                            0.5 *
                            MediaQuery.devicePixelRatioOf(context))
                        .round(),
                  ),
                ),
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

  /// Step progress, top-left of the reserved lane.
  Widget _stepPips(SlmPalette palette) {
    final total = _pack.slots.length + 1;
    final current = _beat == _Beat.mythWhy ? total - 1 : _slot;
    return Positioned(
      top: 14,
      left: 18,
      child: IgnorePointer(
        child: Row(
          children: [
            Text(
              'ধাপ ${enDigits('${current + 1}')}/${enDigits('$total')}',
              style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: SlmColors.gold200),
            ),
            const SizedBox(width: 10),
            for (var i = 0; i < total; i++)
              AnimatedContainer(
                duration: SlmMotion.base,
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 5),
                width: i == current ? 22 : 9,
                height: 9,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: i < current
                      ? SlmColors.emerald400
                      : i == current
                          ? SlmColors.gold300
                          : SlmColors.navy700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Pending ◆ chip: lives in the top lane, right side, never over the cards.
  Widget _pendingDock(bool quiet, SlmPalette palette) {
    return Positioned(
      top: 4,
      right: 12,
      child: IgnorePointer(
        child: SizedBox(
          key: _pendingDockKey,
          width: 112,
          height: 46,
          child: _PendingChip(
            pending: _pending,
            burning: _burning,
            fxToken: _pendingFxToken,
            quiet: quiet,
            celebrate: _celebrate,
            burn: _burn,
          ),
        ),
      ),
    );
  }
}

class _PendingChip extends StatefulWidget {
  const _PendingChip({
    required this.pending,
    required this.burning,
    required this.fxToken,
    required this.quiet,
    required this.celebrate,
    required this.burn,
  });

  final int pending;
  final bool burning;
  final int fxToken;
  final bool quiet;
  final Animation<double> celebrate;
  final Animation<double> burn;

  @override
  State<_PendingChip> createState() => _PendingChipState();
}

class _PendingChipState extends State<_PendingChip> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 760));

  void _sync() => slmSyncLoop(
        context,
        _pulse,
        enabled: !widget.quiet && widget.pending > 0 && !widget.burning,
        reverse: true,
        restAt: 0.5,
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_PendingChip old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final burning = widget.burning;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: burning
              ? const [Color(0xFFF87171), Color(0xFFB91C1C)]
              : const [Color(0xFFFDE68A), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: burning ? const Color(0xFFFFB4B4) : const Color(0xFFFFF7D6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: burning ? const Color(0x99EF4444) : const Color(0x99F59E0B),
            blurRadius: 16,
          ),
        ],
      ),
      child: Text(
        burning ? 'নষ্ট' : '+${enDigits('${widget.pending}')} ◆',
        style: bangla(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF1A1408),
          height: 1.05,
        ),
      ),
    );
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (widget.pending > 0 && !widget.quiet)
          SlmSparkBurst(trigger: widget.fxToken, radius: 70, count: 16),
        if (widget.quiet)
          chip
        else
          AnimatedBuilder(
            animation: Listenable.merge([_pulse, widget.celebrate, widget.burn]),
            child: chip,
            builder: (_, child) {
              final pulse = 0.96 + 0.08 * _pulse.value;
              final pop = Curves.easeOutBack.transform(widget.celebrate.value.clamp(0.0, 1.0));
              final burnT = burning ? widget.burn.value : 0.0;
              return Opacity(
                opacity: (1 - burnT).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 22 * burnT),
                  child: Transform.rotate(
                    angle: 0.35 * burnT,
                    child: Transform.scale(
                      scale: pulse * (0.7 + 0.3 * pop) * (1 - 0.25 * burnT),
                      child: child,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

enum _DealStyle {
  /// Grid tiles flicked off a deck below the board, spinning into place.
  deal,

  /// List rows swept in from the right edge.
  slide,
}

/// Choice card motion: dealt in with a landing squash and a glint, presses
/// down under the finger, shakes on a wrong hit and pops on a right one.
/// All one-shot; nothing loops.
class _AnimatedChoiceCard extends StatefulWidget {
  final int index;
  final bool quiet;
  final _DealStyle style;
  final int hitToken;
  final bool hitGood;
  final VoidCallback? onLaunch;
  final Widget child;

  const _AnimatedChoiceCard({
    super.key,
    required this.index,
    required this.quiet,
    required this.child,
    this.style = _DealStyle.deal,
    this.hitToken = 0,
    this.hitGood = false,
    this.onLaunch,
  });

  @override
  State<_AnimatedChoiceCard> createState() => _AnimatedChoiceCardState();
}

class _AnimatedChoiceCardState extends State<_AnimatedChoiceCard> with TickerProviderStateMixin {
  static const _landAt = 0.74;

  late final AnimationController _deal = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.style == _DealStyle.deal ? 680 : 560),
  );
  late final AnimationController _hit =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  Timer? _delay;
  var _pressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.quiet) {
      _deal.value = 1;
      if (widget.index == 0) widget.onLaunch?.call();
      return;
    }
    final stagger = widget.style == _DealStyle.deal ? 110 : 120;
    _delay = Timer(Duration(milliseconds: 80 + widget.index * stagger), () {
      if (!mounted) return;
      widget.onLaunch?.call();
      _deal.forward();
    });
  }

  @override
  void didUpdateWidget(_AnimatedChoiceCard old) {
    super.didUpdateWidget(old);
    if (widget.hitToken != old.hitToken && widget.hitToken != 0 && !widget.quiet) {
      _hit.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _deal.dispose();
    _hit.dispose();
    super.dispose();
  }

  void _press(bool down) {
    if (_pressed != down) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    final card = Listener(
      onPointerDown: (_) => _press(true),
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
    if (widget.quiet) return card;

    final width = MediaQuery.sizeOf(context).width;
    final deal = widget.style == _DealStyle.deal;
    final leftCol = widget.index.isEven;

    return AnimatedBuilder(
      animation: Listenable.merge([_deal, _hit]),
      child: card,
      builder: (_, child) {
        final t = _deal.value;
        final travel = Curves.easeOutCubic.transform((t / _landAt).clamp(0.0, 1.0));
        final rest = 1 - travel;
        final land = t < _landAt ? 0.0 : (t - _landAt) / (1 - _landAt);
        final squash = math.sin(land * math.pi) * 0.07;

        double dx, dy, angle, scale;
        if (deal) {
          dx = rest * (leftCol ? 110 : -110);
          dy = rest * 320;
          angle = rest * (leftCol ? -0.7 : 0.7);
          scale = 0.5 + 0.5 * travel;
        } else {
          dx = rest * width * 0.85;
          dy = rest * 18;
          angle = rest * 0.14;
          scale = 0.92 + 0.08 * travel;
        }

        final h = _hit.value;
        if (h > 0 && h < 1) {
          if (widget.hitGood) {
            scale *= 1 + 0.09 * math.sin(h * math.pi);
            dy -= 8 * math.sin(h * math.pi);
          } else {
            final fade = 1 - h;
            dx += math.sin(h * math.pi * 7) * 11 * fade;
            angle += math.sin(h * math.pi * 7) * 0.035 * fade;
          }
        }

        final glint = t <= _landAt ? -1.0 : land;
        return Opacity(
          opacity: (t * 4).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: angle,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.diagonal3Values(scale * (1 + squash), scale * (1 - squash), 1),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    child!,
                    if (glint > 0 && glint < 1)
                      Positioned.fill(child: IgnorePointer(child: _Glint(t: glint))),
                    if (h > 0 && h < 1)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (widget.hitGood ? SlmColors.emerald400 : SlmColors.danger)
                                    .withValues(alpha: math.sin(h * math.pi)),
                                width: 2.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One diagonal light sweep across a card as it lands.
class _Glint extends StatelessWidget {
  const _Glint({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Align(
        alignment: Alignment(-1.8 + 3.6 * t, 0),
        child: FractionallySizedBox(
          widthFactor: 0.32,
          heightFactor: 1.6,
          child: Transform.rotate(
            angle: 0.42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.26),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Downward speech tail under the rival's bubble.
class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, -1)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, -1);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => old.fill != fill || old.stroke != stroke;
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
    _bump = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
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
                  final s = 1.0 + 0.55 * math.sin(_bump.value * math.pi);
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
                        color: SlmColors.gold400.withValues(alpha: 0.55),
                        blurRadius: 22,
                        spreadRadius: 1,
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