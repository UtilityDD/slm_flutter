import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../design/slm_design.dart';
import '../admin/dev_unlock.dart';
import '../auth/auth_provider.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_sheet.dart';
import '../game/beat_fx.dart';
import '../game/content_catalog.dart';
import '../game/do_games.dart';
import '../game/game_save.dart';
import '../game/mistakes_book.dart';
import '../game/ladder_builder.dart';
import '../game/learn_board_models.dart';
import '../game/learn_board_runner.dart';
import '../game/learn_explainer_videos.dart';
import '../game/learn_runner.dart';
import '../game/learn_video_gate.dart';
import '../game/level_shell.dart';
import '../game/lucky_toolbox.dart' show ChestTier, ToolboxLines, chestTierNamed;
import '../guide/guide_director.dart';
import '../guide/ladder_guide_host.dart';
import '../guide/mascot_speech_library.dart';
import '../home/lesson_progress_store.dart';
import '../home/lineman_progress.dart';
import '../shell/shell_providers.dart';
import '../training/training_provider.dart';
import '../zero_loss/zero_loss_fx.dart';
import '../zero_loss/zero_loss_ui.dart';
import 'adventure_scenery.dart';
import 'duty_slip_engine.dart';
import 'ladder_focus.dart';
import 'lucky_toolbox_overlay.dart';

/// Monumental golden ladder shell.
/// Rung count + kinds come from [builtLadderProvider] (327).
/// Automatically springs back to the player's current rung when scrolling ends.
class AdventureMap extends ConsumerStatefulWidget {
  final DutySlipEngine engine;
  final void Function(int index) onOpen;
  final ValueNotifier<double> scrollOut;
  final bool muted;

  const AdventureMap({
    super.key,
    required this.engine,
    required this.onOpen,
    required this.scrollOut,
    required this.muted,
  });

  /// Closes the card open on the ladder on screen (a reply or the lucky
  /// toolbox) and returns true; false when none is open. Android back asks
  /// this first, so it closes the card instead of asking to leave the game
  /// (the cards are Stack layers, not routes).
  static bool closeOpenCard() => _AdventureMapState._shown?._closeCard() ?? false;

  @override
  ConsumerState<AdventureMap> createState() => _AdventureMapState();
}

/// The sudden chests ("হঠাৎ উপহার") waiting on the ladder, by ladder index:
/// each stands one rung above the rung whose first clear dropped it
/// (game_save.dart: toolboxChestDrop). The ladder has no other side items
/// (stations removed 2026-11-13); their old `station_*` claim ids stay in
/// GameSave.giftsClaimed, so nothing is ever paid twice.
Map<int, PendingChest> _chestsByIndex(BuiltLadder? built, GameSave save) => chestsByLadderIndex(built, save);

const _chestArt = 'assets/duty_slip/world3d/prop_chest.webp';

class _Reply {
  final String title;
  final String body;

  const _Reply(this.title, this.body);
}

/// The lucky toolbox being opened ("ভাগ্যের টুলবক্স", lucky_toolbox_overlay.dart).
class _ActiveToolbox {
  final PendingChest chest;

  const _ActiveToolbox(this.chest);
}

class _AdventureMapState extends ConsumerState<AdventureMap>
    with TickerProviderStateMixin {
  static const _rowH = 108.0;

  /// Emerald cap sits above the last catalog rung.
  static const _emeraldExtra = 1;

  /// Fallback when the catalog is not loaded yet (see [ladderFallbackSpan]).
  static const _playableFallbackSpan = ladderFallbackSpan;

  /// Contiguous playable prefix from the catalog (stops at first comingSoon).
  int _playableSpan(BuiltLadder? built) => ladderPlayableSpan(built);

  bool _isRungPlayable(int index, BuiltLadder? built) {
    if (index < 0) return false;
    if (built != null && index < built.length) {
      return !built.rungs[index].isComingSoon;
    }
    return index < _playableFallbackSpan;
  }

  int _ladderLen(BuiltLadder? built) =>
      built?.length ?? math.max(_playableFallbackSpan, 40);

  /// Computes the player's current active ladder rung (`focus`) by combining
  /// `engine.unlocked` and cleared rungs in `GameSave.rungProgress`.
  /// Shared with Home (ladder_focus.dart), so Home's `L<n>` is this rung.
  int _computeFocus(BuiltLadder? built, GameSave save) =>
      ladderFocus(built, save, widget.engine.unlocked);

  final _scoreKey = GlobalKey();
  final _deathKey = GlobalKey();
  final _scroll = ScrollController();
  _Reply? _reply;
  _ActiveToolbox? _toolbox;

  /// The lucky toolbox is open.
  bool get _sideBusy => _toolbox != null;

  /// The chest now dropping in (one shot after a first clear).
  String? _dropClaim;
  Timer? _replyAutoClose;
  Timer? _springBackTimer;
  var _activePointers = 0;
  int? _lastFocus;

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _ascent = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7000),
  );
  late final AnimationController _nudgePulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _mist = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 780),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  /// One-shot drop + shake of a new sudden chest; it ends still.
  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    value: 1,
  );

  Timer? _idleTimer;
  Timer? _nudgeCycleTimer;
  int? _nudgeIndex;
  var _nudgeGift = false;
  var _nudgeOnGiftTurn = false;
  /// Nudge cycles shown this idle spell; after [_nudgeMaxCycles] the ladder
  /// stays quiet until the next touch re-arms it.
  static const _nudgeMaxCycles = 3;
  var _nudgeCycles = 0;
  var _nudgeSounded = false;
  var _programmaticScroll = false;
  final _nudgeRng = math.Random();

  /// The ladder's loops (glow, gleam, motes, the live coin, shimmer, the
  /// finish shield) rest once an idle nudge spell ends untouched; the next
  /// touch wakes them. An idle ladder then draws no frames (AGENTS §1).
  final _calm = SlmMotionSettings();

  void _setCalm(bool calm) {
    if (_calm.paused == calm) return;
    calm ? _calm.pause() : _calm.play();
    _syncLoops();
  }

  /// The ladder on screen, for [AdventureMap.closeOpenCard].
  static _AdventureMapState? _shown;

  /// Closes the reply or the lucky toolbox, as their own close does.
  bool _closeCard() {
    if (_toolbox != null) {
      _closeToolbox();
      return true;
    }
    if (_reply != null) {
      _closeKinetic();
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _shown = this;
    _scroll.addListener(_publish);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pin(initial: true);
      _armIdle();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLoops();
  }

  /// Glow and gleam loop only while looping motion is allowed (slmLoopsOn);
  /// TickerMode already mutes them while another route covers the ladder.
  void _syncLoops() {
    if (slmLoopsOn(context) && _calm.paused) {
      // Idle calm: frozen where they are, no snap.
      _glow.stop();
      _ascent.stop();
    } else if (slmLoopsOn(context)) {
      if (!_glow.isAnimating) _glow.repeat(reverse: true);
      if (!_ascent.isAnimating) _ascent.repeat();
    } else {
      _glow
        ..stop()
        ..value = 0.6;
      _ascent
        ..stop()
        ..value = 0.35;
      _clearNudge();
    }
  }

  /// False while another route sits on top of the ladder.
  bool _ladderVisible() => ModalRoute.isCurrentOf(context) ?? true;

  void _onFingerScroll() {
    _springBackTimer?.cancel();
    _clearNudge();
    _armIdle();
    final guide = ProviderScope.containerOf(context).read(guideDirectorProvider);
    if (guide.mood == GuideMood.sleep) {
      ProviderScope.containerOf(context).read(guideDirectorProvider.notifier).wake();
    }
  }

  /// Schedules an automatic elastic spring-back to the player's current rung
  /// whenever the user finishes scrolling or lifts their finger away from `focus`.
  void _scheduleAutoSpringBack(int focus) {
    _springBackTimer?.cancel();
    if (_activePointers > 0 || _programmaticScroll) return;
    if (_reply != null || _sideBusy) return;
    if (!_scrolledAwayFromFocus(focus)) return;

    _springBackTimer = Timer(const Duration(milliseconds: 520), () {
      if (!mounted || _activePointers > 0 || _programmaticScroll) return;
      if (_reply != null || _sideBusy) return;
      final built = ref.read(builtLadderProvider).value;
      final save = ref.read(gameSaveProvider);
      final currentFocus = _computeFocus(built, save);
      if (_scrolledAwayFromFocus(currentFocus)) {
        unawaited(_springBackToFocus(currentFocus));
      }
    });
  }

  Future<void> _springBackToFocus(int focus) async {
    if (!mounted || !_scroll.hasClients) return;
    final view = _scroll.position.viewportDimension;
    final want = (focus * _rowH) - (view * 0.24);
    final clamped = want.clamp(0.0, _scroll.position.maxScrollExtent);
    if ((_scroll.offset - clamped).abs() < 6) return;
    _programmaticScroll = true;
    try {
      await _scroll.animateTo(
        clamped,
        duration: const Duration(milliseconds: 680),
        curve: Curves.easeOutBack,
      );
    } finally {
      _programmaticScroll = false;
    }
  }

  void _clearNudge() {
    _nudgeCycleTimer?.cancel();
    _nudgeCycleTimer = null;
    if (_nudgePulse.isAnimating) _nudgePulse.stop();
    if (_nudgeIndex != null && mounted) {
      setState(() {
        _nudgeIndex = null;
        _nudgeGift = false;
      });
    } else {
      _nudgeIndex = null;
      _nudgeGift = false;
    }
  }

  void _armIdle() {
    _setCalm(false);
    _nudgeCycles = 0;
    _nudgeSounded = false;
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 24), () {
      if (!mounted) return;
      _startIdleNudge();
    });
  }

  /// Waiting sudden chests currently on-screen.
  List<int> _visibleGiftIndices() {
    if (!_scroll.hasClients) return const [];
    final built = ref.read(builtLadderProvider).value;
    final save = ref.read(gameSaveProvider);
    final view = _scroll.position.viewportDimension;
    final scrolled = _scroll.offset;
    final bottomInset = MediaQuery.paddingOf(context).bottom + 18;
    final out = <int>[];
    for (final i in _chestsByIndex(built, save).keys) {
      final fromBottom = bottomInset + i * _rowH + _rowH / 2 - scrolled;
      if (fromBottom > 36 && fromBottom < view - 36) out.add(i);
    }
    return out;
  }

  Future<void> _softScrollToIndex(int index) async {
    if (!_scroll.hasClients) return;
    final view = _scroll.position.viewportDimension;
    final scrolled = _scroll.offset;
    final bottomInset = MediaQuery.paddingOf(context).bottom + 18;
    final fromBottom = bottomInset + index * _rowH + _rowH / 2 - scrolled;
    if (fromBottom > view * 0.20 && fromBottom < view * 0.78) return;
    final want = (index * _rowH) - (view * 0.24);
    final clamped = want.clamp(0.0, _scroll.position.maxScrollExtent);
    _programmaticScroll = true;
    try {
      await _scroll.animateTo(
        clamped,
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutBack,
      );
    } finally {
      _programmaticScroll = false;
    }
  }

  void _applyNudgeTarget({required bool giftTurn}) {
    if (!mounted) return;
    final built = ref.read(builtLadderProvider).value;
    final save = ref.read(gameSaveProvider);
    final focus = _computeFocus(built, save);
    final gifts = _visibleGiftIndices();
    late final int target;
    late final bool asGift;
    if (giftTurn && gifts.isNotEmpty) {
      final pool = gifts.length == 1
          ? gifts
          : gifts.where((g) => g != _nudgeIndex).toList(growable: false);
      final pick = pool.isEmpty ? gifts : pool;
      target = pick[_nudgeRng.nextInt(pick.length)];
      asGift = true;
    } else {
      target = focus;
      asGift = false;
    }
    _nudgeCycles++;
    if (_nudgeIndex != target || _nudgeGift != asGift) {
      setState(() {
        _nudgeIndex = target;
        _nudgeGift = asGift;
      });
    }

    // Check if the lineman is engaged in speech, tips, or user interaction
    final guide = ProviderScope.containerOf(context).read(guideDirectorProvider);
    final isEngaged = MascotTalk.active.value ||
        guide.line.isNotEmpty ||
        guide.gesture != GuideGesture.none ||
        _reply != null ||
        _sideBusy;

    // Never overrule active lineman engagement with idle nudge speech/audio
    if (!isEngaged) {
      ProviderScope.containerOf(context)
          .read(guideDirectorProvider.notifier)
          .nudgePlay(gift: asGift);
      // One sound per idle spell, not one every cycle.
      if (!widget.muted && !_nudgeSounded) {
        _nudgeSounded = true;
        unawaited(
          ZlFx.cue(
            asGift ? 'sounds/intro/glass.ogg' : 'sounds/intro/confirm.ogg',
            volume: 0.35,
            muted: false,
          ),
        );
      }
    }
  }

  void _startIdleNudge() {
    if (!mounted || !slmLoopsOn(context)) return;
    if (_reply != null || _sideBusy) return;
    if (MascotTalk.active.value) {
      // The guide is talking: try again later (so the spell, and the calm
      // after it, still come).
      _armIdle();
      return;
    }
    if (_nudgeIndex != null) return;
    if (!_ladderVisible()) {
      // A lesson or quiz is on top: check again later, stay silent now.
      _armIdle();
      return;
    }
    // A waiting chest on screen gets the first nudge.
    _nudgeOnGiftTurn = _visibleGiftIndices().isNotEmpty;
    _nudgePulse
      ..value = 0
      ..repeat();
    _applyNudgeTarget(giftTurn: _nudgeOnGiftTurn);
    _nudgeCycleTimer?.cancel();
    _nudgeCycleTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _nudgeIndex == null) return;
      if (_nudgeCycles >= _nudgeMaxCycles || !_ladderVisible()) {
        // Done for this idle spell; the next touch re-arms it.
        _clearNudge();
        if (_nudgeCycles >= _nudgeMaxCycles) _setCalm(true);
        return;
      }
      if (MascotTalk.active.value || _reply != null || _sideBusy) {
        return;
      }
      _nudgeOnGiftTurn = !_nudgeOnGiftTurn;
      final gifts = _visibleGiftIndices();
      if (_nudgeOnGiftTurn && gifts.isEmpty) {
        _nudgeOnGiftTurn = false;
      }
      _applyNudgeTarget(giftTurn: _nudgeOnGiftTurn);
    });
  }

  @override
  void didUpdateWidget(covariant AdventureMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine.unlocked != widget.engine.unlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pin();
        _maybePlayDrop();
      });
    }
  }

  void _publish() {
    if (!_scroll.hasClients) return;
    if (widget.scrollOut.value != _scroll.offset) {
      widget.scrollOut.value = _scroll.offset;
    }
  }

  void _pin({bool initial = false}) {
    if (!mounted || !_scroll.hasClients) return;
    final built = ref.read(builtLadderProvider).value;
    final save = ref.read(gameSaveProvider);
    final focus = _computeFocus(built, save);
    final view = _scroll.position.viewportDimension;
    if (initial) {
      // Opens straight on the current rung (Home's "চলুন, L<n>"), or on the
      // rung Home's gift chip asked for, with a waiting chest nearby in view.
      final anchor = built == null ? null : widget.engine.ladderAnchor;
      if (built != null) widget.engine.ladderAnchor = null;
      final want = anchor != null
          ? (anchor * _rowH) - (view * 0.40)
          : _openOffset(focus, _chestsByIndex(built, save).keys, view);
      // The jump's scroll notifications are not a finger: no spring-back.
      _programmaticScroll = true;
      _scroll.jumpTo(want.clamp(0.0, _scroll.position.maxScrollExtent));
      _programmaticScroll = false;
      return;
    }
    final target = (focus * _rowH) - (view * 0.24);
    final clamped = target.clamp(0.0, _scroll.position.maxScrollExtent);
    _programmaticScroll = true;
    _scroll
        .animateTo(
          clamped,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutBack,
        )
        .whenComplete(() => _programmaticScroll = false);
  }

  /// The opening scroll: [focus] a quarter up the screen; a chest waiting a
  /// few rungs below or above shifts the view so both are seen.
  double _openOffset(int focus, Iterable<int> chests, double view) {
    final base = (focus * _rowH) - (view * 0.24);
    final topRoom = MediaQuery.paddingOf(context).top + 58 + _rowH;
    final bottomPad = MediaQuery.paddingOf(context).bottom + 88;
    int? near;
    for (final c in chests) {
      if ((c - focus).abs() > 4) continue;
      if (near == null || (c - focus).abs() < (near - focus).abs()) near = c;
    }
    if (near == null || near == focus) return base;
    // Item i's centre sits (bottomPad + i·row + row/2 − offset) above the bottom.
    double fromBottom(int i, double off) => bottomPad + i * _rowH + _rowH / 2 - off;
    final off = near < focus
        ? math.min(base, near * _rowH - _rowH * 0.1)
        : math.max(base, bottomPad + near * _rowH + _rowH / 2 - (view - topRoom));
    final f = fromBottom(focus, off);
    final c = fromBottom(near, off);
    final fits = f > _rowH / 2 && f < view - topRoom && c > _rowH / 2 && c < view - topRoom;
    return fits ? off : base;
  }

  @override
  void dispose() {
    if (identical(_shown, this)) _shown = null;
    _idleTimer?.cancel();
    _nudgeCycleTimer?.cancel();
    _replyAutoClose?.cancel();
    _springBackTimer?.cancel();
    _scroll.removeListener(_publish);
    _scroll.dispose();
    _glow.dispose();
    _ascent.dispose();
    _nudgePulse.dispose();
    _calm.dispose();
    _mist.dispose();
    _shake.dispose();
    _drop.dispose();
    super.dispose();
  }

  /// Maps a Do rung on the 327-rung ladder to its corresponding [dsLevels] index
  /// without Learn rungs (at 0, 3, 6...) shadowing Do levels.
  int _resolveDoLevelIndex(int ladderIndex, BuiltLadder? built) {
    // The catalog names the level by topic (pack.legacyLevel); play order is only a fallback.
    final mapped = built != null && ladderIndex >= 0 && ladderIndex < built.length
        ? built.rungs[ladderIndex].pack.legacyLevel
        : null;
    if (mapped != null) {
      final at = dsLevels.indexWhere((l) => l.number == mapped);
      if (at >= 0) return at;
    }
    return _orderedDoLevelIndex(ladderIndex, built);
  }

  /// Old play-order bridge: the Nth Do rung opens `dsLevels[N]`.
  int _orderedDoLevelIndex(int ladderIndex, BuiltLadder? built) {
    if (built == null || ladderIndex >= built.length) {
      return (ladderIndex % dsLevels.length).clamp(0, dsLevels.length - 1);
    }
    var doOrd = 0;
    for (var i = 0; i < ladderIndex; i++) {
      if (!built.rungs[i].isLearn) doOrd++;
    }
    return (doOrd % dsLevels.length).clamp(0, dsLevels.length - 1);
  }

  void _openLevel(int index, {BuiltLadder? built}) {
    _clearNudge();
    _armIdle();
    // Before the catalog is built a rung has no id: a tap would open a legacy
    // level and save progress under its old number. It loads in a moment.
    if (built == null) return;
    final save = ref.read(gameSaveProvider);
    final focus = _computeFocus(built, save);
    final rung = index < built.length ? built.rungs[index] : null;
    final locked = !dsPlayAllLevels && index > focus;
    if (locked) {
      _pulseMist(shake: true, focus: focus);
      return;
    }

    // Catalog Learn (playable) opens the interactive field-card deck — never a fall path.
    if (rung != null && rung.isLearn && !rung.isComingSoon) {
      if (gameNeedsVerifyNow(context, index + 1)) {
        showVerifySheet(context);
        return;
      }
      HapticFeedback.selectionClick();
      unawaited(ref.read(gameSaveProvider.notifier).setCurrentRung(rung.id));
      unawaited(_openLearn(rung, index));
      return;
    }

    // A Do/gate rung whose game type is built opens it in the shared level shell.
    final shellGame = rung != null && !rung.isLearn ? doGameFor(rung.pack) : null;
    final shellCtx = shellGame != null ? levelContextAt(built, index) : null;
    if (shellGame != null && shellCtx != null) {
      if (gameNeedsVerifyNow(context, dsLevels[_orderedDoLevelIndex(index, built)].number)) {
        showVerifySheet(context);
        return;
      }
      HapticFeedback.selectionClick();
      unawaited(ref.read(gameSaveProvider.notifier).setCurrentRung(rung!.id));
      unawaited(_openRoute(rung, index, (_) => shellGame(shellCtx, widget.muted)));
      return;
    }

    // Never fall through to a legacy dsLevels screen when the catalog already
    // named a shell engine (e.g. gate_docket). That used to reopen Level 33
    // field night for the Rank Gate whenever the shell builder missed.
    final engine = rung?.pack.engineType ?? '';
    if (rung != null &&
        !rung.isLearn &&
        engine.isNotEmpty &&
        engine != 'placeholder' &&
        engine != 'learn_cards') {
      _hintComingSoon(focus: focus);
      return;
    }

    final soon = !_isRungPlayable(index, built);
    if (soon) {
      _hintComingSoon(focus: focus);
      return;
    }
    final doIdx = _resolveDoLevelIndex(index, built);
    final spec = dsLevels[doIdx];
    // Verify gate stays where it was (by play order), whichever level the rung opens.
    if (gameNeedsVerifyNow(context, dsLevels[_orderedDoLevelIndex(index, built)].number)) {
      showVerifySheet(context);
      return;
    }
    HapticFeedback.selectionClick();
    unawaited(
      ref
          .read(gameSaveProvider.notifier)
          .setCurrentRung(rung?.id ?? '${spec.number}'),
    );
    widget.onOpen(doIdx);
  }

  Future<void> _openLearn(BuiltRung rung, int index) async {
    final lessonId = rung.lesson?.id ?? rung.def.lessonId ?? '';
    if (lessonId.isEmpty) {
      _hintComingSoon();
      return;
    }
    final boardPack = learnBoardPackFor(lessonId);
    final youtubeId = LearnExplainerVideos.youtubeIdFor(lessonId);
    await _openRoute(
      rung,
      index,
      (_) {
        if (boardPack != null && youtubeId != null) {
          // Guide → explainer video → portrait → guide → board.
          return LearnVideoGatePage(
            rungId: rung.id,
            lessonId: lessonId,
            ladderIndex: index,
            pack: boardPack,
            youtubeId: youtubeId,
            muted: widget.muted,
          );
        }
        if (boardPack != null) {
          return LearnBoardRunnerPage(
            rungId: rung.id,
            lessonId: lessonId,
            ladderIndex: index,
            pack: boardPack,
            muted: widget.muted,
          );
        }
        return LearnRunnerPage(
          rungId: rung.id,
          lessonId: lessonId,
          ladderIndex: index,
          muted: widget.muted,
        );
      },
    );
  }

  /// Opens a level page (Learn, or a Do game in the level shell) over the
  /// ladder; on a clear the next rung unlocks and the ladder scrolls to it.
  Future<void> _openRoute(BuiltRung rung, int index, WidgetBuilder builder) async {
    // Level owns the mascot — kill ladder idle nudge / gag while the route is up.
    _clearNudge();
    _idleTimer?.cancel();
    _idleTimer = null;
    ref.read(guideDirectorProvider.notifier).setLevelFocus(true);
    unawaited(MascotSpeechLibrary.stop());
    bool savedClear() => ref.read(gameSaveProvider).rungProgress[rung.id] == 'cleared';
    final wasCleared = savedClear();
    final cleared = await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(builder: builder));
    if (!mounted) return;
    ref.read(guideDirectorProvider.notifier).setLevelFocus(false);
    _armIdle();
    // A pass is saved before the level can be left, so trust the save too.
    if (cleared == true || (!wasCleared && savedClear())) {
      widget.engine.unlockThrough(index + 1);
      setState(() {});
      unawaited(_softScrollToIndex(index + 1));
    }
    _maybePlayDrop();
  }

  /// A first clear dropped a sudden chest (GameSaveController.lastChestDrop):
  /// once the ladder is visible again, it falls beside the next rung with one
  /// existing sound and a single shake, then holds still until opened.
  void _maybePlayDrop() {
    if (!mounted || !_ladderVisible()) return;
    final ctrl = ref.read(gameSaveProvider.notifier);
    final drop = ctrl.lastChestDrop;
    if (drop == null) return;
    ctrl.lastChestDrop = null;
    if (!ref.read(gameSaveProvider).toolbox.chests.any((c) => c.claimId == drop.claimId)) return;
    setState(() => _dropClaim = drop.claimId);
    HapticFeedback.mediumImpact();
    if (!widget.muted) {
      unawaited(ZlFx.cue('sounds/intro/impact_metal.ogg', volume: 0.5, muted: false));
    }
    if (!MascotTalk.active.value) {
      ref.read(guideDirectorProvider.notifier).say(
            mood: GuideMood.glad,
            line: ToolboxLines.dropped,
            speakVoice: true,
            muted: widget.muted,
          );
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _drop.value = 1;
    } else {
      unawaited(_drop.forward(from: 0));
    }
  }

  bool _scrolledAwayFromFocus(int focus) {
    if (!_scroll.hasClients) return false;
    final view = _scroll.position.viewportDimension;
    final scrolled = _scroll.offset;
    final bottomInset = MediaQuery.paddingOf(context).bottom + 18;
    final fromBottom = bottomInset + focus * _rowH + _rowH / 2 - scrolled;
    return fromBottom < view * 0.16 || fromBottom > view * 0.80;
  }

  void _pulseMist({required bool shake, int? focus}) {
    if (MediaQuery.disableAnimationsOf(context)) {
      HapticFeedback.selectionClick();
      return;
    }
    HapticFeedback.mediumImpact();
    _mist.forward(from: 0);
    if (shake) _shake.forward(from: 0);
    if (!widget.muted) {
      unawaited(ZlFx.cue('sounds/intro/glass.ogg', volume: 0.28, muted: false));
    }
    if (focus != null) {
      _scheduleAutoSpringBack(focus);
    }
  }

  void _showKinetic({
    required String title,
    required String body,
    required bool speak,
  }) {
    if (speak && !widget.muted) {
      unawaited(MascotSpeechLibrary.speak(body, muted: false));
    }
    if (!mounted) return;
    _replyAutoClose?.cancel();
    setState(() => _reply = _Reply(title, enDigits(body)));
    _replyAutoClose = Timer(const Duration(milliseconds: 3000), () {
      if (!mounted || _reply == null) return;
      setState(() => _reply = null);
      _armIdle();
      final built = ref.read(builtLadderProvider).value;
      final save = ref.read(gameSaveProvider);
      _scheduleAutoSpringBack(_computeFocus(built, save));
    });
  }

  void _closeKinetic() {
    _replyAutoClose?.cancel();
    if (_reply == null) return;
    setState(() => _reply = null);
    _armIdle();
    final built = ref.read(builtLadderProvider).value;
    final save = ref.read(gameSaveProvider);
    _scheduleAutoSpringBack(_computeFocus(built, save));
  }

  /// A waiting chest opens the lucky toolbox (once: opening takes it off the
  /// ladder). With keys on and no key, a short note says how to get one.
  void _openChest(PendingChest chest) {
    if (_reply != null || _sideBusy) return;
    _springBackTimer?.cancel();
    final save = ref.read(gameSaveProvider);
    if (save.giftsClaimed.contains(chest.claimId)) return;
    if (ToolboxFlags.keysEnabled && save.toolbox.keys <= 0) {
      _showKinetic(title: ToolboxLines.noKeyTitle, body: ToolboxLines.noKeyBody, speak: true);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _toolbox = _ActiveToolbox(chest));
  }

  void _closeToolbox() {
    if (_toolbox == null) return;
    unawaited(MascotSpeechLibrary.stop());
    setState(() => _toolbox = null);
    _armIdle();
    final built = ref.read(builtLadderProvider).value;
    final save = ref.read(gameSaveProvider);
    _scheduleAutoSpringBack(_computeFocus(built, save));
  }

  void _hintComingSoon({int? focus}) {
    _clearNudge();
    _pulseMist(shake: false, focus: focus);
    _showKinetic(
      title: 'শীঘ্রই আসছে',
      body: 'এই ধাপটি এখনো খোলেনি।',
      speak: false,
    );
  }

  void _hintEmerald() {
    _clearNudge();
    HapticFeedback.selectionClick();
    ProviderScope.containerOf(context)
        .read(guideDirectorProvider.notifier)
        .react(GuideMood.inspire);
    _showKinetic(
      title: 'মৃত্যুহীন লক্ষ্য',
      body: 'পথের শেষ! প্রতি পদে নিরাপদ থাকাই আমাদের আসল লক্ষ্য।',
      speak: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    final ladderAsync = ref.watch(builtLadderProvider);
    final built = ladderAsync.value;
    final catalogLen = _ladderLen(built);
    final itemCount = catalogLen + _emeraldExtra;
    final save = ref.watch(gameSaveProvider);
    ref.watch(devUnlockProvider);

    final focus = _computeFocus(built, save);
    if (_lastFocus != null && _lastFocus != focus) {
      final nextFocus = focus;
      _lastFocus = focus;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_springBackToFocus(nextFocus));
      });
    } else {
      _lastFocus = focus;
    }
    final openUpTo =
        dsPlayAllLevels ? math.max(0, _playableSpan(built) - 1) : focus;
    final quiet = MediaQuery.disableAnimationsOf(context);
    final chromeBoot = ladderAsync.isLoading && built == null;
    final chests = _chestsByIndex(built, save);
    // A new sudden chest: its one-shot drop plays once the ladder is in view.
    ref.listen(gameSaveProvider.select((s) => s.toolbox.chests.length), (prev, next) {
      if (next > (prev ?? next)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybePlayDrop());
      }
    });

    // Always bring the player to their achieved rung when the catalog settles or focus changes.
    ref.listen(builtLadderProvider, (prev, next) {
      if (next.hasValue && !(prev?.hasValue ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _pin(initial: true);
        });
      }
    });

    final currentRung =
        built != null && focus < built.length ? built.rungs[focus] : null;
    final currentIsLearn = currentRung?.isLearn ?? (focus % 3 == 0);

    // Nothing here listens to an animation: header, bands and guide build on
    // state changes only. Each moving piece (coin glow, rail gleam, prop
    // zoom, nudge halo, mist, shake) has its own small listener.
    return Builder(
      builder: (context) {
        final Animation<double> glow =
            quiet ? const AlwaysStoppedAnimation(0.6) : _glow;
        final journey = itemCount * _rowH;
        final Animation<double> light =
            quiet ? const AlwaysStoppedAnimation(0.35) : _ascent;
        final topInset = MediaQuery.paddingOf(context).top + 58;
        final bottomInset = MediaQuery.paddingOf(context).bottom + 24;

        return DeathMomentHost(
          deathKey: _deathKey,
          onSettled: () {
            // Fall option C: the climb resumes at the first Do level to prove
            // again (Learn rungs stay done), not at the module's first rung.
            final latestSave = ref.read(gameSaveProvider);
            final resume = _computeFocus(ref.read(builtLadderProvider).value, latestSave);
            if (resume != focus) {
              setState(() {});
              unawaited(_softScrollToIndex(resume));
            }
          },
          child: ScoreFlyHost(
            scoreKey: _scoreKey,
            child: Listener(
              onPointerDown: (_) {
                _activePointers++;
                _springBackTimer?.cancel();
                if (_calm.paused) _armIdle();
              },
              onPointerUp: (_) {
                _activePointers = math.max(0, _activePointers - 1);
                if (_activePointers == 0) {
                  _scheduleAutoSpringBack(focus);
                }
              },
              onPointerCancel: (_) {
                _activePointers = math.max(0, _activePointers - 1);
                if (_activePointers == 0) {
                  _scheduleAutoSpringBack(focus);
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: AdventureWorld(
                        scroll: _scroll,
                        drift: _ascent,
                        motion: !quiet,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _shake,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(
                        quiet
                            ? 0.0
                            : math.sin(_shake.value * math.pi * 6) *
                                5 *
                                (1 - _shake.value),
                        0,
                      ),
                      // The bands' coins, shimmer and shield follow the calm.
                      child: SlmMotionScope(settings: _calm, child: child!),
                    ),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (_programmaticScroll) return false;
                        if (n is ScrollStartNotification &&
                            n.dragDetails != null) {
                          _onFingerScroll();
                        } else if (n is ScrollUpdateNotification &&
                            n.dragDetails != null) {
                          _onFingerScroll();
                        } else if (n is ScrollEndNotification) {
                          _scheduleAutoSpringBack(focus);
                        }
                        return false;
                      },
                      child: ListView.builder(
                        controller: _scroll,
                        scrollDirection: Axis.vertical,
                        reverse: true,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        clipBehavior: Clip.hardEdge,
                        itemCount: itemCount,
                        itemExtent: _rowH,
                        padding: EdgeInsets.only(
                          top: topInset,
                          bottom: bottomInset + 64,
                        ),
                        itemBuilder: (context, i) {
                          final cap = i == catalogLen;
                          final rung = !cap && built != null && i < built.length
                              ? built.rungs[i]
                              : null;
                          final soon = !cap && !_isRungPlayable(i, built);
                          final fog = !cap && i > focus + 3;
                          final chest = cap ? null : chests[i];
                          // Read on scroll ticks by the prop's own builder.
                          double zoom() {
                            if (quiet || chest == null) return 1.0;
                            final view = _scroll.hasClients &&
                                    _scroll.position.hasViewportDimension
                                ? _scroll.position.viewportDimension
                                : 640.0;
                            final scrolled =
                                _scroll.hasClients ? _scroll.offset : 0.0;
                            final fromBottom =
                                bottomInset + i * _rowH + _rowH / 2 - scrolled;
                            final dist = (((view - fromBottom) / view) - 0.5)
                                    .abs()
                                    .clamp(0.0, 0.5) *
                                2;
                            final closeness = 1 - dist;
                            return 0.42 + 1.08 * closeness * closeness;
                          }

                          final number =
                              cap ? catalogLen : (rung?.number ?? (i + 1));
                          final learnCleared = rung != null &&
                              save.rungProgress[rung.id] == 'cleared';
                          final bridgeCleared =
                              _isRungPlayable(i, built) && i < focus;
                          final cleared =
                              !soon && !cap && (learnCleared || bridgeCleared);
                          final prove = !soon &&
                              !cap &&
                              rung != null &&
                              save.rungProgress[rung.id] == 'prove';
                          return _MapBand(
                            index: i,
                            number: number,
                            soon: soon,
                            fog: fog,
                            cap: cap,
                            cleared: cleared && !prove,
                            prove: prove,
                            current: !soon && !cap && i == focus,
                            locked: !cap && (soon || i > openUpTo),
                            glow: glow,
                            kind: rung?.kind ?? CatalogRungKind.doKind,
                            chest: chest,
                            chestDrop: chest != null && chest.claimId == _dropClaim ? _drop : null,
                            keys: ToolboxFlags.keysEnabled ? save.toolbox.keys : null,
                            zoom: zoom,
                            scroll: quiet ? null : _scroll,
                            motion: !quiet,
                            light: light,
                            journey: journey,
                            idleNudge: _nudgeIndex == i,
                            nudgeGift: _nudgeGift && _nudgeIndex == i,
                            nudgePulse: quiet
                                ? const AlwaysStoppedAnimation(0.0)
                                : _nudgePulse,
                            onLevel: cap
                                ? _hintEmerald
                                : soon
                                    ? () => _hintComingSoon(focus: focus)
                                    : () => _openLevel(i, built: built),
                            onChest: chest == null
                                ? null
                                : () {
                                    _clearNudge();
                                    _armIdle();
                                    _openChest(chest);
                                  },
                          );
                        },
                      ),
                    ),
                  ),
                  // Right-edge vertical climb progress line (ground -> module notches -> player -> emerald)
                  Positioned(
                    right: 6,
                    top: topInset + 18,
                    bottom: bottomInset + 118,
                    child: IgnorePointer(
                      child: _LadderAltitudeTrack(
                        currentRung: focus,
                        totalRungs: catalogLen,
                        glow: glow,
                      ),
                    ),
                  ),
                  if (chromeBoot)
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: SlmColors.gold300,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _mist,
                        builder: (context, _) {
                          final mistT = quiet
                              ? 0.0
                              : Curves.easeOut.transform(
                                  (_mist.value < 0.45
                                          ? _mist.value / 0.45
                                          : (1 - _mist.value) / 0.55)
                                      .clamp(0.0, 1.0),
                                );
                          if (mistT <= 0.01) return const SizedBox.shrink();
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0, -0.1),
                                radius: 1.15,
                                colors: [
                                  const Color(0x33D7E4F5)
                                      .withValues(alpha: 0.18 * mistT),
                                  const Color(0x99A8B8CC)
                                      .withValues(alpha: 0.42 * mistT),
                                  const Color(0xCC050A16)
                                      .withValues(alpha: 0.55 * mistT),
                                ],
                                stops: const [0.0, 0.45, 1.0],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x99050A16), Color(0x00050A16)],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.paddingOf(context).top,
                        ),
                        child: _TopHeader(
                          engine: e,
                          scoreKey: _scoreKey,
                          deathKey: _deathKey,
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    ),
                  ),
                  // Bottom-left / center primary play button ("▶ পরের ধাপ")
                  Positioned(
                    left: 16,
                    bottom: MediaQuery.paddingOf(context).bottom + 14,
                    child: _NextRungPlayBar(
                      rungNumber: focus + 1,
                      isLearn: currentIsLearn,
                      glow: glow,
                      onTap: () async {
                        if (_scrolledAwayFromFocus(focus)) {
                          await _springBackToFocus(focus);
                        }
                        if (!mounted) return;
                        _openLevel(focus, built: built);
                      },
                    ),
                  ),
                  // Unified Rive-like Mascot dock & welcome stage
                  Positioned.fill(
                    child: LadderGuideHost(muted: widget.muted),
                  ),
                  if (_reply != null)
                    Positioned.fill(
                      child: _KineticReply(
                        title: _reply!.title,
                        body: _reply!.body,
                        still: quiet,
                        onClose: _closeKinetic,
                      ),
                    ),
                  if (_toolbox != null)
                    Positioned.fill(
                      key: ValueKey('toolbox-${_toolbox!.chest.claimId}'),
                      child: LuckyToolboxOverlay(
                        claimId: _toolbox!.chest.claimId,
                        gateChest: _toolbox!.chest.gate,
                        startTier: chestTierNamed(_toolbox!.chest.tier),
                        muted: widget.muted,
                        onClose: _closeToolbox,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Primary one-tap play button on the Ladder ("▶ পরের ধাপ").
class _NextRungPlayBar extends StatelessWidget {
  final int rungNumber;
  final bool isLearn;
  final Animation<double> glow;
  final VoidCallback onTap;

  const _NextRungPlayBar({
    required this.rungNumber,
    required this.isLearn,
    required this.glow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kindLabel = isLearn ? 'শিখুন' : 'মাঠের কাজ';
    return SlmTactile(
      onTap: onTap,
      semanticLabel: 'পরের ধাপ',
      builder: (context, press, child) => Transform.scale(
        scale: 1 - 0.05 * press,
        child: child,
      ),
      // Only the glowing rim follows the glow clock; the label is built once.
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: glow,
          builder: (context, child) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF6D379), Color(0xFFC89228)],
              ),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: SlmColors.ivory.withValues(alpha: 0.55 + 0.35 * glow.value),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: SlmColors.gold300
                      .withValues(alpha: 0.25 + 0.25 * glow.value),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
                const BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: SlmColors.navy950,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 18,
                  color: SlmColors.gold300,
                ),
              ),
              const SizedBox(width: 9),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enDigits('পরের ধাপ · $rungNumber'),
                    style: zlText(
                      13.5,
                      weight: FontWeight.w900,
                      color: SlmColors.navy950,
                      height: 1.05,
                    ),
                  ),
                  Text(
                    kindLabel,
                    style: zlText(
                      10.5,
                      weight: FontWeight.w800,
                      color: const Color(0xFF281B06),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin vertical progress line on the right edge showing the 10 module notches,
/// the top emerald goal, and the player's current altitude dot.
class _LadderAltitudeTrack extends StatelessWidget {
  final int currentRung;
  final int totalRungs;
  final Animation<double> glow;

  const _LadderAltitudeTrack({
    required this.currentRung,
    required this.totalRungs,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalRungs <= 1
        ? 0.0
        : (currentRung / (totalRungs - 1)).clamp(0.0, 1.0);
    return SizedBox(
      width: 12,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _AltitudeTrackPainter(progress: progress, glow: glow),
        ),
      ),
    );
  }
}

class _AltitudeTrackPainter extends CustomPainter {
  final double progress;
  final Animation<double> glow;

  _AltitudeTrackPainter({required this.progress, required this.glow})
      : super(repaint: glow);

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final topY = 8.0;
    final botY = size.height - 6.0;
    final span = math.max(1.0, botY - topY);

    // Background track
    canvas.drawLine(
      Offset(x, topY),
      Offset(x, botY),
      Paint()
        ..color = SlmColors.ivory.withValues(alpha: 0.16)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // 10 module notches
    for (var m = 1; m <= 10; m++) {
      final ny = botY - (m / 10.0) * span;
      canvas.drawLine(
        Offset(x - 3, ny),
        Offset(x + 3, ny),
        Paint()
          ..color = SlmColors.gold300.withValues(alpha: 0.35)
          ..strokeWidth = 1.2,
      );
    }

    // Active climb fill
    final dotY = botY - progress * span;
    canvas.drawLine(
      Offset(x, dotY),
      Offset(x, botY),
      Paint()
        ..color = SlmColors.gold300.withValues(alpha: 0.78)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // Top emerald diamond
    canvas.drawCircle(
      Offset(x, topY),
      3.5,
      Paint()..color = SlmColors.emerald300.withValues(alpha: 0.85),
    );

    // Player glowing dot
    canvas.drawCircle(
      Offset(x, dotY),
      5.5 + 1.5 * glow.value,
      Paint()
        ..color = SlmColors.gold300.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(x, dotY),
      3.8,
      Paint()..color = SlmColors.gold200,
    );
  }

  @override
  bool shouldRepaint(covariant _AltitudeTrackPainter old) =>
      old.progress != progress || old.glow != glow;
}

/// Outer brushed-gold bezel around a dark navy or emerald housing.
class _GoldShell extends StatelessWidget {
  final double radius;
  final double rim;
  final Widget child;

  const _GoldShell({
    required this.radius,
    this.rim = 1.25,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final inner = math.max(0.0, radius - rim);
    return Container(
      padding: EdgeInsets.all(rim),
      decoration: BoxDecoration(
        gradient: SlmGradients.gold,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x8C000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: SlmGradients.navyCard,
          borderRadius: BorderRadius.circular(inner),
        ),
        child: child,
      ),
    );
  }
}

class _TopHeader extends ConsumerWidget {
  final DutySlipEngine engine;
  final GlobalKey scoreKey;
  final GlobalKey deathKey;
  final VoidCallback onBack;

  const _TopHeader({
    required this.engine,
    required this.scoreKey,
    required this.deathKey,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final profile = ref.watch(authProvider).profile;
    final localDone = ref.watch(allCompletedLessonsProvider);
    final ladder = ref.watch(trainingLadderProvider).value;
    var highestDone = 0;
    if (ladder != null) {
      for (final m in ladder) {
        if (!m.isCompleted) break;
        highestDone = m.moduleNumber;
      }
    }
    final path = linemanPath(
      profile,
      extraCompleted: localDone,
      highestCompletedModule: highestDone > 0 ? highestDone : null,
    );
    final save = ref.watch(gameSaveProvider);
    final rankFromSave = save.rankIndex;
    final rankLevel =
        rankFromSave > 0 ? rankFromSave : (path.achieved == 0 ? 1 : path.achieved);
    final rank = linemanBadgeName(rankLevel, bn);
    final calm = save.deaths == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          _CircleIcon(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 10),
          // Takes the free space (left-aligned) and ellipsizes on narrow phones
          // instead of overflowing the bar.
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _RankPill(label: rank, streak: save.safeStreak),
            ),
          ),
          const SizedBox(width: 8),
          KeyedSubtree(
            key: scoreKey,
            child: _ScoreChip(
              mark: '◆',
              value: enDigits('${save.points}'),
              color: SlmColors.gold200,
            ),
          ),
          const SizedBox(width: 8),
          // Tap the 💀 chip: "আমার ভুলের খাতা".
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MistakesBookPage()),
            ),
            child: KeyedSubtree(
              key: deathKey,
              child: _ScoreChip(
                mark: '💀',
                value: enDigits('${save.deaths}'),
                color: calm ? SlmColors.emerald300 : SoftDanger.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankPill extends StatelessWidget {
  final String label;
  final int streak;

  const _RankPill({required this.label, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.45)),
        color: const Color(0xB3050A16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_rounded, size: 13, color: SlmColors.gold300),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: zlText(
                12,
                weight: FontWeight.w800,
                color: SlmColors.gold200,
                height: 1.1,
              ),
            ),
          ),
          if (streak > 0) ...[
            const SizedBox(width: 6),
            Text(
              enDigits('· $streak'),
              style: zlText(
                11,
                weight: FontWeight.w800,
                color: SlmColors.emerald300,
                height: 1.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String mark;
  final String value;
  final Color color;

  const _ScoreChip({
    required this.mark,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xB3050A16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$mark  $value',
        style: zlText(14, weight: FontWeight.w800, color: color, height: 1.1),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SlmTactile(
      onTap: onTap,
      builder: (context, press, child) =>
          Transform.scale(scale: 1 - 0.06 * press, child: child),
      child: _GoldShell(
        radius: 18,
        rim: 1.15,
        child: SizedBox(
          width: 33,
          height: 33,
          child: Icon(icon, size: 17, color: SlmColors.gold100),
        ),
      ),
    );
  }
}

class _MapBand extends StatelessWidget {
  final int index;
  final int number;
  final bool soon;
  final bool fog;
  final bool cap;
  final bool cleared;

  /// Passed before the last death: must be proven again (fall option C).
  final bool prove;
  final bool current;
  final bool locked;
  final Animation<double> glow;
  final CatalogRungKind kind;

  /// A sudden chest waiting beside this rung, if any.
  final PendingChest? chest;

  /// Its one-shot drop (only the chest that just appeared).
  final Animation<double>? chestDrop;

  /// Lucky-toolbox keys in hand, shown small by a closed chest (null = keys off).
  final int? keys;
  final double Function() zoom;
  final ScrollController? scroll;
  final bool motion;
  final Animation<double> light;
  final double journey;
  final bool idleNudge;
  final bool nudgeGift;
  final Animation<double> nudgePulse;
  final VoidCallback? onLevel;
  final VoidCallback? onChest;

  const _MapBand({
    required this.index,
    required this.number,
    required this.soon,
    required this.fog,
    required this.cap,
    required this.cleared,
    this.prove = false,
    required this.current,
    required this.locked,
    required this.glow,
    required this.kind,
    required this.chest,
    this.chestDrop,
    this.keys,
    required this.zoom,
    required this.scroll,
    required this.motion,
    required this.light,
    required this.journey,
    required this.idleNudge,
    required this.nudgeGift,
    required this.nudgePulse,
    required this.onLevel,
    required this.onChest,
  });

  @override
  Widget build(BuildContext context) {
    // Not a LayoutBuilder: any animation inside one relayouts it each frame,
    // and that repaints the whole band past the coin's own RepaintBoundary.
    // The ladder is full width; each row is the list's itemExtent tall.
    return Builder(
      builder: (context) {
        final w = MediaQuery.sizeOf(context).width;
        const h = _AdventureMapState._rowH;
        final rungY = h * 0.58;
        final sideLeft = index.isEven;
        final chestTop = const [0.0, 8.0, 16.0][index % 3];
        final gleam = CustomPaint(
          size: Size(w, h),
          painter: _RailGleamPainter(
            index: index,
            light: light,
            journey: journey,
            height: h,
          ),
        );

        if (cap) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                size: Size(w, h),
                painter: const _GoldenLadderPainter(
                  fog: false,
                  cap: true,
                ),
              ),
              gleam,
              Center(
                child: _FinishMark(glow: glow, motion: motion, onTap: onLevel),
              ),
            ],
          );
        }

        final coinHalf = current
            ? (kind == CatalogRungKind.gate ? 34.0 : 30.0)
            : (kind == CatalogRungKind.gate ? 28.0 : 24.0);
        final coinSize = coinHalf * 2;

        return Opacity(
          opacity: fog ? 0.42 : 1,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(w, h),
                painter: _GoldenLadderPainter(
                  fog: fog,
                ),
              ),
              gleam,
              Positioned(
                left: w / 2 - coinHalf,
                top: rungY - coinHalf,
                width: coinSize,
                height: coinSize,
                child: _IdleNudgeHalo(
                  active: idleNudge && !nudgeGift,
                  pulse: nudgePulse,
                  child: _LevelCoin(
                    number: number,
                    soon: soon,
                    cleared: cleared,
                    prove: prove,
                    current: current,
                    locked: locked,
                    kind: kind,
                    motion: motion,
                    onTap: onLevel,
                  ),
                ),
              ),
              // Climber avatar badge standing right beside the active rung
              if (current)
                Positioned(
                  left: w / 2 + coinHalf + 6,
                  top: rungY - 22,
                  child: IgnorePointer(
                    child: _ClimberOnRungBadge(glow: glow, motion: motion),
                  ),
                ),
              if (chest != null)
                Positioned(
                  left: sideLeft ? 10 : null,
                  right: sideLeft ? null : 18,
                  top: chestTop,
                  width: 92,
                  height: 82,
                  child: _StationZoom(
                    scroll: scroll,
                    zoom: zoom,
                    child: _IdleNudgeHalo(
                      active: idleNudge && nudgeGift,
                      pulse: nudgePulse,
                      child: _ChestPlaque(
                        key: ValueKey('toolbox-chest-$index'),
                        chest: chest!,
                        keys: keys,
                        drop: chestDrop,
                        onTap: onChest,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Small glowing lineman helmet avatar standing on the player's current rung.
class _ClimberOnRungBadge extends StatelessWidget {
  final Animation<double> glow;
  final bool motion;

  const _ClimberOnRungBadge({required this.glow, required this.motion});

  @override
  Widget build(BuildContext context) {
    // Bob and rim follow the glow clock on their own layer; the avatar
    // image is built once.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: glow,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, motion ? -3.0 * glow.value : 0.0),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SlmColors.navy900,
              border: Border.all(
                color: SlmColors.emerald300
                    .withValues(alpha: 0.75 + 0.25 * glow.value),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: SlmColors.emerald400
                      .withValues(alpha: 0.35 + 0.25 * glow.value),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/duty_slip/dress/coach_ready.webp',
            cacheWidth: (38 * MediaQuery.devicePixelRatioOf(context)).round(),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, _, _) => const Icon(
              Icons.engineering_rounded,
              size: 20,
              color: SlmColors.gold300,
            ),
          ),
        ),
      ),
    );
  }
}

/// Scales a waiting chest with the scroll position; only this transform
/// rebuilds while the ladder scrolls.
class _StationZoom extends StatelessWidget {
  final ScrollController? scroll;
  final double Function() zoom;
  final Widget child;

  const _StationZoom({
    required this.scroll,
    required this.zoom,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final s = scroll;
    if (s == null) {
      return Transform.scale(
        scale: zoom(),
        alignment: Alignment.center,
        child: child,
      );
    }
    return AnimatedBuilder(
      animation: s,
      child: child,
      builder: (context, child) => Transform.scale(
        scale: zoom(),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _IdleNudgeHalo extends StatelessWidget {
  final bool active;
  final Animation<double> pulse;
  final Widget child;

  const _IdleNudgeHalo({
    required this.active,
    required this.pulse,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: OverflowBox(
              maxWidth: 140,
              maxHeight: 140,
              alignment: Alignment.center,
              child: CustomPaint(
                size: const Size(140, 140),
                painter: _NudgeRingPainter(
                  progress: pulse,
                  color: SlmColors.gold300,
                ),
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: pulse,
          child: child,
          builder: (context, child) => Transform.scale(
            scale: 1.0 +
                0.14 * math.sin(pulse.value.clamp(0.0, 1.0) * math.pi * 2),
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _NudgeRingPainter extends CustomPainter {
  final Animation<double> progress;
  final Color color;

  _NudgeRingPainter({required this.progress, required this.color})
      : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final t = progress.value.clamp(0.0, 1.0);
    for (final phase in const [0.0, 0.33, 0.66]) {
      final p = (t + phase) % 1.0;
      final radius = size.shortestSide * (0.22 + 0.28 * p);
      final opacity = (1.0 - p).clamp(0.0, 1.0);
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = color.withValues(alpha: 0.72 * opacity),
      );
      canvas.drawCircle(
        c,
        radius * 0.78,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = SlmColors.emerald300.withValues(alpha: 0.42 * opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NudgeRingPainter old) =>
      old.progress != progress || old.color != color;
}

/// The travelling gleam on the two rails. Repaints only while the gleam is
/// inside (or just leaving) this band, not on every tick of the 7 s loop.
class _RailGleamPainter extends CustomPainter {
  final int index;
  final Animation<double> light;
  final double journey;
  final double height;

  _RailGleamPainter({
    required this.index,
    required this.light,
    required this.journey,
    required this.height,
  }) : super(
          repaint: _GleamGate(
            light,
            (v) => _inBand(_gleamY(v, index, journey), height),
          ),
        );

  static double _gleamY(double v, int index, double journey) {
    const rowH = _AdventureMapState._rowH;
    return rowH - (v * journey - index * rowH);
  }

  static bool _inBand(double gleamY, double h) =>
      gleamY > -28 && gleamY < h + 28;

  @override
  void paint(Canvas canvas, Size size) {
    final gleamY = _gleamY(light.value, index, journey);
    if (!_inBand(gleamY, size.height)) return;
    final (leftX, rightX) = _GoldenLadderPainter.railsX(size.width);
    for (final x in [leftX, rightX]) {
      canvas.drawCircle(
        Offset(x, gleamY),
        14,
        Paint()
          ..color = const Color(0x88FFF3C4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RailGleamPainter old) =>
      old.index != index ||
      old.light != light ||
      old.journey != journey ||
      old.height != height;
}

/// Forwards ticks of [source] only while [inside] is true, plus one tick
/// after it turns false so the last gleam is wiped.
class _GleamGate extends Listenable {
  final Animation<double> source;
  final bool Function(double value) inside;
  final _wrapped = <VoidCallback, VoidCallback>{};

  _GleamGate(this.source, this.inside);

  @override
  void addListener(VoidCallback listener) {
    var was = inside(source.value);
    void gate() {
      final now = inside(source.value);
      if (now || was) listener();
      was = now;
    }

    _wrapped[listener] = gate;
    source.addListener(gate);
  }

  @override
  void removeListener(VoidCallback listener) {
    final gate = _wrapped.remove(listener);
    if (gate != null) source.removeListener(gate);
  }
}

class _GoldenLadderPainter extends CustomPainter {
  final bool fog;
  final bool cap;

  const _GoldenLadderPainter({
    required this.fog,
    this.cap = false,
  });

  static (double, double) railsX(double w) {
    const railW = 11.0;
    final span = w * 0.38;
    final gap = (span - railW) / 2;
    return (w / 2 - gap, w / 2 + gap);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const railW = 11.0;
    final span = w * 0.38;
    final gap = (span - railW) / 2;
    final leftX = w / 2 - gap;
    final rightX = w / 2 + gap;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(leftX - 8, 0, rightX + 12, h),
        const Radius.circular(12),
      ),
      Paint()
        ..color = const Color(0x33040A12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    _rail(canvas, leftX, h);
    _rail(canvas, rightX, h);
    if (!cap) {
      _rung(canvas, leftX, rightX, h * 0.58, fog);
    }
  }

  void _rail(Canvas canvas, double x, double h) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, h / 2), width: 11, height: h + 2),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      body.shift(const Offset(2.4, 0)),
      Paint()..color = const Color(0xFF3A280C),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF5C4212),
            Color(0xFFC6A15A),
            Color(0xFFFFF6D2),
            Color(0xFFE8C56A),
            Color(0xFF8A6420),
            Color(0xFF3A280C),
          ],
          stops: [0.0, 0.2, 0.42, 0.56, 0.8, 1.0],
        ).createShader(body.outerRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x - 0.6, h / 2), width: 2.2, height: h),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF14915F),
    );
  }

  void _rung(Canvas canvas, double leftX, double rightX, double y, bool fog) {
    final rung = Rect.fromLTRB(leftX - 1, y - 4.5, rightX + 1, y + 4.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rung.shift(const Offset(1.6, 3)),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF2C1C08),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rung, const Radius.circular(4)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: fog
              ? const [Color(0xFFD9C48A), Color(0xFF8A7040), Color(0xFF4A3818)]
              : const [
                  Color(0xFFFFF8DC),
                  Color(0xFFE6C56E),
                  Color(0xFF8C6822),
                  Color(0xFF4A3410),
                ],
          stops: fog ? const [0.0, 0.55, 1.0] : const [0.0, 0.32, 0.7, 1.0],
        ).createShader(rung),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(rung.left + 6, rung.top + 1.1, rung.right - 6, rung.top + 2.4),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xDDFFF8E6),
    );
    for (final x in [leftX, rightX]) {
      canvas.drawCircle(Offset(x, y), 4.6, Paint()..color = const Color(0xFFB8893A));
      canvas.drawCircle(Offset(x, y), 3.3, Paint()..color = const Color(0xFF0E7A4E));
      canvas.drawCircle(
        Offset(x - 0.8, y - 0.9),
        1.15,
        Paint()..color = const Color(0xFFB6FFD8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoldenLadderPainter oldDelegate) =>
      oldDelegate.fog != fog || oldDelegate.cap != cap;
}

const _noFilter = ColorFilter.mode(Color(0x00000000), BlendMode.dst);

/// Grey-silver: luminance with a cool tint.
const _silverFilter = ColorFilter.matrix(<double>[
  0.25, 0.60, 0.10, 0, 18, //
  0.25, 0.60, 0.10, 0, 22, //
  0.25, 0.60, 0.10, 0, 30, //
  0, 0, 0, 1, 0,
]);

class _LevelCoin extends StatefulWidget {
  final int number;
  final bool soon;
  final bool cleared;
  final bool prove;
  final bool current;
  final bool locked;
  final CatalogRungKind kind;
  final bool motion;
  final VoidCallback? onTap;

  const _LevelCoin({
    required this.number,
    required this.soon,
    required this.cleared,
    this.prove = false,
    required this.current,
    required this.locked,
    required this.kind,
    required this.motion,
    required this.onTap,
  });

  @override
  State<_LevelCoin> createState() => _LevelCoinState();
}

class _LevelCoinState extends State<_LevelCoin> with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _spin;
  late final AnimationController _flash;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also told when "remove animations" or the ladder's calm changes.
    _syncLoops();
  }

  @override
  void didUpdateWidget(covariant _LevelCoin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current ||
        oldWidget.motion != widget.motion ||
        oldWidget.locked != widget.locked ||
        oldWidget.soon != widget.soon) {
      _syncLoops();
    }
  }

  void _syncLoops() {
    final quiet = !widget.motion || slmReduceMotion(context);
    final liveCurrent = widget.current && !widget.locked && !widget.soon;
    if (liveCurrent && !quiet && slmLoopsOn(context)) {
      if (!_breath.isAnimating) _breath.repeat(reverse: true);
      if (!_spin.isAnimating) _spin.repeat();
    } else if (liveCurrent && !quiet) {
      // A paused motion scope (the ladder's calm) freezes it where it is.
      _breath.stop();
      _spin.stop();
    } else {
      _breath.stop();
      _breath.value = liveCurrent ? 0.55 : 0;
      _spin.stop();
      _spin.value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _spin.dispose();
    _flash.dispose();
    super.dispose();
  }

  void _onTap() {
    final quiet = !widget.motion || slmReduceMotion(context);
    final live = !widget.locked && !widget.soon;
    if (!quiet && live && (widget.current || widget.cleared)) {
      _flash.forward(from: 0);
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    // A level to prove again stays visible in silver (with a ↻ badge) even
    // above the climber, so the fall after a death reads at a glance.
    final silver = widget.prove && !widget.soon && !widget.current;
    final bronze = !silver && (widget.soon || (widget.locked && !widget.current));
    final gate = widget.kind == CatalogRungKind.gate;
    final learn = widget.kind == CatalogRungKind.learn;
    final current = widget.current && !bronze;
    final cleared = widget.cleared && !bronze && !current;
    final base = gate ? 56.0 : 48.0;
    final size = current ? base + 8 : base;
    final accent = gate
        ? SlmColors.emerald300
        : learn
            ? SlmColors.ivory
            : SlmColors.gold300;
    final asset = current
        ? 'assets/duty_slip/world3d/coin_current_3d.webp'
        : cleared
            ? 'assets/duty_slip/world3d/coin_cleared_3d.webp'
            : 'assets/duty_slip/world3d/medallion_bronze_3d.webp';
    final numberColor = bronze
        ? SlmColors.mist.withValues(alpha: 0.7)
        : current
            ? SlmColors.ivory
            : cleared
                ? const Color(0xFFE8D7A8)
                : SlmColors.ivory;

    // The coin face (rim, art, number) never changes while it breathes:
    // build it once and let the loop only move the halo, ring and flash.
    final face = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: current
              ? SlmColors.gold300.withValues(alpha: 0.9)
              : cleared
                  ? SlmColors.gold200.withValues(alpha: 0.55)
                  : accent.withValues(alpha: bronze ? 0.2 : 0.35),
          width: current ? 2.2 : (gate ? 1.6 : 1.15),
        ),
        boxShadow: cleared
            ? [
                BoxShadow(
                  color: SlmColors.gold300.withValues(alpha: 0.18),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ColorFiltered(
            colorFilter: silver ? _silverFilter : _noFilter,
            child: Image.asset(
              silver ? 'assets/duty_slip/world3d/coin_cleared_3d.webp' : asset,
              width: size,
              height: size,
              cacheWidth: 180,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            ),
          ),
          if (widget.prove && !widget.soon)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFDDE3EA),
                  border: Border.all(color: const Color(0xFF6B7682), width: 1.2),
                ),
                child: const Icon(Icons.replay_rounded, size: 12, color: Color(0xFF2B3440)),
              ),
            ),
          Text(
            enDigits('${widget.number}'),
            style: zlText(
              gate ? (current ? 16 : 15) : (current ? 17 : 16),
              weight: FontWeight.w900,
              color: numberColor,
            ).copyWith(
              shadows: const [
                Shadow(
                  color: Color(0xDD000000),
                  offset: Offset(0, 1.2),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final pressDepth = current ? 0.09 : (cleared ? 0.06 : 0.05);

    final animated = AnimatedBuilder(
      animation: Listenable.merge([_breath, _spin, _flash]),
      child: face,
      builder: (context, face) {
        final breath = current ? (0.55 + 0.45 * _breath.value) : 0.0;
        final flash = Curves.easeOut.transform(_flash.value.clamp(0.0, 1.0));
        final flashOut = flash < 0.55
            ? (flash / 0.55)
            : (1 - (flash - 0.55) / 0.45).clamp(0.0, 1.0);

        final disc = Opacity(
          opacity: bronze ? 0.42 : 1,
          child: SizedBox(
            width: size + (current ? 16 : 0),
            height: size + (current ? 16 : 0),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (current)
                  Container(
                    width: size + 18 + 10 * breath,
                    height: size + 18 + 10 * breath,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: SlmColors.gold300
                              .withValues(alpha: 0.22 + 0.28 * breath),
                          blurRadius: 14 + 10 * breath,
                          spreadRadius: 1 + 2 * breath,
                        ),
                        BoxShadow(
                          color: SlmColors.emerald400
                              .withValues(alpha: 0.14 + 0.12 * breath),
                          blurRadius: 22,
                        ),
                      ],
                    ),
                  ),
                if (current)
                  Transform.rotate(
                    angle: _spin.value * 6.283185307179586,
                    child: CustomPaint(
                      size: Size(size + 10, size + 10),
                      painter: _EmeraldRingPainter(progress: breath),
                    ),
                  ),
                if (flashOut > 0.02 && (current || cleared))
                  Container(
                    width: size + 8 + 28 * flash,
                    height: size + 8 + 28 * flash,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (current ? SlmColors.gold300 : SlmColors.gold200)
                            .withValues(alpha: 0.8 * flashOut),
                        width: current ? 2.4 : 1.6,
                      ),
                    ),
                  ),
                face!,
              ],
            ),
          ),
        );

        if (current) {
          return SlmShimmer(intensity: 0.22 + 0.1 * breath, child: disc);
        } else if (cleared) {
          return SlmShimmer(intensity: 0.08, child: disc);
        }
        return disc;
      },
    );

    return SlmTactile(
      onTap: widget.onTap == null ? null : _onTap,
      builder: (context, press, child) => Transform.scale(
        scale: 1 - pressDepth * press,
        child: child,
      ),
      // The live coin breathes every frame: keep that off the band's layer.
      child: current ? RepaintBoundary(child: animated) : animated,
    );
  }
}

class _EmeraldRingPainter extends CustomPainter {
  final double progress;

  _EmeraldRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 1.5;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..color = SlmColors.emerald300.withValues(alpha: 0.35 + 0.45 * progress);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -1.2,
      2.1,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      2.0,
      1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _EmeraldRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// A sudden chest waiting beside a rung: a still picture (no idle loop) with
/// a soft glow in its tier colour; a gate chest is a little bigger. It drops
/// in and shakes once when it first appears ([drop]), then holds still.
class _ChestPlaque extends StatelessWidget {
  final PendingChest chest;
  final int? keys;
  final Animation<double>? drop;
  final VoidCallback? onTap;

  const _ChestPlaque({
    super.key,
    required this.chest,
    this.keys,
    this.drop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glow = switch (chestTierNamed(chest.tier)) {
      ChestTier.wood => const Color(0xCCFFD56A),
      ChestTier.silver => const Color(0xCCE4ECF5),
      ChestTier.gold => const Color(0xCCFFC94A),
    };
    final size = chest.gate ? 1.0 : 0.88;
    final still = SizedBox(
      width: 92,
      height: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 64 * size,
            height: 64 * size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: glow.withValues(alpha: 0.28),
              boxShadow: [BoxShadow(color: glow, blurRadius: 16)],
            ),
          ),
          Image.asset(
            _chestArt,
            width: 92 * size,
            height: 82 * size,
            cacheWidth: 280,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
          if (keys != null)
            Positioned(
              left: 2,
              top: 0,
              child: _ToolboxKeyPill(keys: keys!),
            ),
        ],
      ),
    );
    final d = drop;
    final body = d == null
        ? still
        : RepaintBoundary(
            child: AnimatedBuilder(
              animation: d,
              child: still,
              builder: (context, child) {
                final v = d.value;
                final fall = Curves.bounceOut.transform((v / 0.6).clamp(0.0, 1.0));
                final shakeT = ((v - 0.6) / 0.4).clamp(0.0, 1.0);
                final shake = math.sin(shakeT * math.pi * 6) * 5 * (1 - shakeT);
                return Opacity(
                  opacity: (v * 4).clamp(0.0, 1.0),
                  child: Transform.translate(offset: Offset(shake, (1 - fall) * -140), child: child),
                );
              },
            ),
          );
    return SlmTactile(
      onTap: onTap,
      semanticLabel: ToolboxLines.name,
      builder: (context, press, child) => Transform.scale(scale: 1 - 0.05 * press, child: child),
      child: body,
    );
  }
}

/// Key count by a closed lucky toolbox (Material key icon; no key art).
class _ToolboxKeyPill extends StatelessWidget {
  final int keys;

  const _ToolboxKeyPill({required this.keys});

  @override
  Widget build(BuildContext context) {
    final edge = keys > 0 ? SlmColors.gold300 : const Color(0x99B8C6DC);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xE60A1426),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: edge, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.vpn_key_rounded, size: 11, color: edge),
          const SizedBox(width: 2),
          Text(
            enDigits('$keys'),
            style: zlText(10.5, weight: FontWeight.w900, color: SlmColors.ivory),
          ),
        ],
      ),
    );
  }
}

class _FinishMark extends StatelessWidget {
  final Animation<double> glow;
  final bool motion;
  final VoidCallback? onTap;

  const _FinishMark({
    required this.glow,
    required this.motion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shield =
        AnimatedSafetyShield(size: 78, animate: motion, entrance: false);
    Widget glowAt(double pulse, Widget shield) => Transform.scale(
      scale: motion ? 1 + 0.06 * pulse : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color.lerp(
                const Color(0xFFE8C56B),
                const Color(0xFF3DDC97),
                pulse,
              )!
                  .withValues(alpha: 0.72),
              blurRadius: 22 + 12 * pulse,
              spreadRadius: 2 + pulse,
            ),
          ],
        ),
        child: shield,
      ),
    );
    final mark = motion
        ? RepaintBoundary(
            child: AnimatedBuilder(
              animation: glow,
              child: shield,
              builder: (context, shield) => glowAt(glow.value, shield!),
            ),
          )
        : glowAt(0.65, shield);
    return SlmTactile(
      onTap: onTap,
      builder: (context, press, child) =>
          Transform.scale(scale: 1 - 0.05 * press, child: child),
      child: mark,
    );
  }
}

class _KineticReply extends StatefulWidget {
  final String title;
  final String body;
  final bool still;
  final VoidCallback onClose;

  const _KineticReply({
    required this.title,
    required this.body,
    required this.still,
    required this.onClose,
  });

  @override
  State<_KineticReply> createState() => _KineticReplyState();
}

class _KineticReplyState extends State<_KineticReply>
    with SingleTickerProviderStateMixin {
  late final AnimationController _play = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 980),
  );

  @override
  void initState() {
    super.initState();
    if (widget.still) {
      _play.value = 1;
    } else {
      _play.forward();
    }
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleWords =
        widget.title.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final bodyWords =
        widget.body.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return GestureDetector(
      onTap: widget.onClose,
      child: ColoredBox(
        color: const Color(0xB3060C16),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: AnimatedBuilder(
              animation: _play,
              builder: (context, _) {
                final count = titleWords.length + bodyWords.length;
                final step = count <= 1 ? 0.0 : 0.62 / (count - 1);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _KineticLine(
                      words: titleWords,
                      clock: _play,
                      start: 0,
                      step: step,
                      style: zlText(
                        28,
                        weight: FontWeight.w900,
                        color: SlmColors.gold100,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _KineticLine(
                      words: bodyWords,
                      clock: _play,
                      start: titleWords.length,
                      step: step,
                      style: zlText(
                        16,
                        weight: FontWeight.w600,
                        color: SlmColors.ivory,
                        height: 1.45,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _KineticLine extends StatelessWidget {
  final List<String> words;
  final Animation<double> clock;
  final int start;
  final double step;
  final TextStyle style;

  const _KineticLine({
    required this.words,
    required this.clock,
    required this.start,
    required this.step,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 7,
      runSpacing: 4,
      children: [
        for (var i = 0; i < words.length; i++)
          _KineticWord(
            word: words[i],
            clock: clock,
            index: start + i,
            step: step,
            style: style,
          ),
      ],
    );
  }
}

class _KineticWord extends StatelessWidget {
  final String word;
  final Animation<double> clock;
  final int index;
  final double step;
  final TextStyle style;

  const _KineticWord({
    required this.word,
    required this.clock,
    required this.index,
    required this.step,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final begin = (index * step).clamp(0.0, 0.72);
    final t = Interval(
      begin,
      (begin + 0.28).clamp(begin + 0.01, 1.0),
      curve: Curves.easeOutCubic,
    ).transform(clock.value);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * 16),
        child: Text(word, textAlign: TextAlign.center, style: style),
      ),
    );
  }
}
