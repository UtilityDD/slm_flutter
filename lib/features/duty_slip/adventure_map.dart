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
import '../game/ladder_builder.dart';
import '../game/learn_board_models.dart';
import '../game/learn_board_runner.dart';
import '../game/learn_runner.dart';
import '../game/level_shell.dart';
import '../guide/ai_lineman_guide.dart';
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

  @override
  ConsumerState<AdventureMap> createState() => _AdventureMapState();
}

enum _Station { tips, hourly, identify, gift, life, lesson }

_Station? _stationAt(int index) => switch (index % 8) {
      1 => _Station.tips,
      2 => _Station.hourly,
      3 => _Station.identify,
      5 => _Station.gift,
      6 => _Station.life,
      7 => _Station.lesson,
      _ => null,
    };

/// One-time side-item reward id, keyed by the rung the item stands beside —
/// never by ladder position (AGENTS §3).
String _stationClaimId(_Station s, BuiltLadder? built, int index) {
  final rungId = built != null && index >= 0 && index < built.length ? built.rungs[index].id : null;
  return rungId == null ? _stationLegacyClaimId(s, index) : 'station_${s.name}@$rungId';
}

/// Old index-based id: still honoured so earlier claims are never paid twice.
String _stationLegacyClaimId(_Station s, int index) => 'station_${s.name}_$index';

bool _stationClaimed(GameSave save, _Station s, BuiltLadder? built, int index) =>
    save.giftsClaimed.contains(_stationClaimId(s, built, index)) ||
    save.giftsClaimed.contains(_stationLegacyClaimId(s, index));

enum _GiftFace { none, missed, active, upcoming, opened }

class _Flight {
  final int index;
  final _Station station;
  final bool large;

  const _Flight(this.index, this.station, this.large);
}

class _Reply {
  final String title;
  final String body;

  const _Reply(this.title, this.body);
}

class _ActiveSideChallenge {
  final int index;
  final _Station station;
  final String asset;
  final SideItemChallenge challenge;

  /// Stable reward id ([_stationClaimId]) and the old index id it replaces.
  final String claimId;
  final String legacyClaimId;

  const _ActiveSideChallenge({
    required this.index,
    required this.station,
    required this.asset,
    required this.challenge,
    required this.claimId,
    required this.legacyClaimId,
  });
}

const _tipHelmet = 'assets/duty_slip/world3d/prop_shield.webp';
const _tipGloves = 'assets/duty_slip/world3d/prop_ppe_gloves.webp';
const _tipHarness = 'assets/duty_slip/world3d/prop_ppe_harness.webp';
const _tipBoots = 'assets/duty_slip/world3d/prop_ppe_boots.webp';
const _tipVest = 'assets/duty_slip/world3d/prop_ppe_vest.webp';
const _tipLock = 'assets/duty_slip/world3d/prop_ppe_lock.webp';
const _tipRope = 'assets/duty_slip/world3d/prop_ppe_rope.webp';
const _tipCone = 'assets/duty_slip/world3d/prop_ppe_cone.webp';
const _tipGoggles = 'assets/duty_slip/world3d/prop_ppe_goggles.webp';

const _tipCycle = <String>[
  _tipHelmet,
  _tipGloves,
  _tipHarness,
  _tipBoots,
  _tipVest,
  _tipLock,
  _tipRope,
  _tipCone,
  _tipGoggles,
];

/// Safety-tip plaques follow the lesson on that rung: helmet, gloves, harness, and the rest of the kit.
String _tipAsset(int index) {
  final n = index + 1;
  return switch (n) {
    1 || 5 || 6 || 26 => _tipVest,
    2 => _tipHelmet,
    3 || 22 => _tipGloves,
    4 || 7 || 11 || 12 || 13 => _tipHarness,
    8 || 18 => _tipLock,
    9 || 14 => _tipCone,
    10 => _tipRope,
    15 || 16 || 20 => _tipHelmet,
    17 || 21 => _tipGoggles,
    19 => _tipBoots,
    _ => _tipCycle[index % _tipCycle.length],
  };
}

String _assetFor(_Station station, int index) => switch (station) {
      _Station.gift => 'assets/duty_slip/world3d/prop_chest.webp',
      _Station.hourly => 'assets/duty_slip/world3d/prop_clock.webp',
      _Station.identify => 'assets/duty_slip/world3d/prop_identify.webp',
      _Station.lesson => 'assets/duty_slip/world3d/prop_books.webp',
      _Station.life => 'assets/duty_slip/world3d/prop_tools.webp',
      _Station.tips => _tipAsset(index),
    };

class _AdventureMapState extends ConsumerState<AdventureMap>
    with TickerProviderStateMixin {
  static const _rowH = 108.0;

  /// Emerald cap sits above the last catalog rung.
  static const _emeraldExtra = 1;

  /// First 31 rungs (all of Module 1: 10 lessons × 3 rungs + 1 Gate) are playable
  /// via LearnRunnerPage + the 14 active Do drills in [dsLevels].
  static const _playableLadderSpan = 31;

  bool _isRungPlayable(int index, BuiltLadder? built) {
    if (index < 0) return false;
    if (built != null && index < built.length) {
      final r = built.rungs[index];
      if (r.isLearn && !r.isComingSoon) return true;
    }
    return index < _playableLadderSpan;
  }

  int _ladderLen(BuiltLadder? built) =>
      built?.length ?? math.max(_playableLadderSpan, 40);

  /// Computes the player's current active ladder rung (`focus`) by combining
  /// `engine.unlocked` and cleared rungs in `GameSave.rungProgress`.
  int _computeFocus(BuiltLadder? built, GameSave save) {
    final len = _ladderLen(built);
    final maxPlayable = math.min(len, _playableLadderSpan);
    var focus =
        widget.engine.unlocked.clamp(0, math.max(0, maxPlayable - 1)).toInt();
    if (built != null) {
      for (var i = 0; i < maxPlayable; i++) {
        final r = built.rungs[i];
        final cleared = save.rungProgress[r.id] == 'cleared';
        if (cleared && i >= focus) {
          focus = (i + 1).clamp(0, math.max(0, maxPlayable - 1)).toInt();
        } else if (!cleared && i >= focus) {
          break;
        }
      }
    }
    return focus;
  }

  final _scoreKey = GlobalKey();
  final _deathKey = GlobalKey();
  final _scroll = ScrollController();
  final _seen = <int>{};
  _Flight? _flight;
  _Reply? _reply;
  _ActiveSideChallenge? _sideChallenge;
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

  @override
  void initState() {
    super.initState();
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
    if (slmLoopsOn(context)) {
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
    if (_flight != null || _reply != null || _sideChallenge != null) return;
    if (!_scrolledAwayFromFocus(focus)) return;

    _springBackTimer = Timer(const Duration(milliseconds: 520), () {
      if (!mounted || _activePointers > 0 || _programmaticScroll) return;
      if (_flight != null || _reply != null || _sideChallenge != null) return;
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
    _nudgeCycles = 0;
    _nudgeSounded = false;
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 24), () {
      if (!mounted) return;
      _startIdleNudge();
    });
  }

  /// Gift chests currently on-screen (any face except opened).
  List<int> _visibleGiftIndices() {
    if (!_scroll.hasClients) return const [];
    final built = ref.read(builtLadderProvider).value;
    final save = ref.read(gameSaveProvider);
    final live = math.min(_ladderLen(built), _playableLadderSpan);
    final focus = _computeFocus(built, save);
    final view = _scroll.position.viewportDimension;
    final scrolled = _scroll.offset;
    final bottomInset = MediaQuery.paddingOf(context).bottom + 18;
    final out = <int>[];
    for (var i = 0; i < live; i++) {
      if (_stationAt(i) != _Station.gift) continue;
      final soon = !_isRungPlayable(i, built);
      final face = _giftFace(_Station.gift, i, focus, soon, save);
      if (face == _GiftFace.opened || face == _GiftFace.none) continue;
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
        _sideChallenge != null;

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
    if (_flight != null || _reply != null || _sideChallenge != null) return;
    if (MascotTalk.active.value) return;
    if (_nudgeIndex != null) return;
    if (!_ladderVisible()) {
      // A lesson or quiz is on top: check again later, stay silent now.
      _armIdle();
      return;
    }
    _nudgeOnGiftTurn = false;
    _nudgePulse
      ..value = 0
      ..repeat();
    _applyNudgeTarget(giftTurn: false);
    _nudgeCycleTimer?.cancel();
    _nudgeCycleTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _nudgeIndex == null) return;
      if (_nudgeCycles >= _nudgeMaxCycles || !_ladderVisible()) {
        // Done for this idle spell; the next touch re-arms it.
        _clearNudge();
        return;
      }
      if (MascotTalk.active.value || _reply != null || _sideChallenge != null) {
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _pin());
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
    final target = (focus * _rowH) - (view * 0.24);
    final clamped = target.clamp(0.0, _scroll.position.maxScrollExtent);
    _programmaticScroll = true;
    if (initial) {
      _scroll.jumpTo(0);
      _scroll
          .animateTo(
            clamped,
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
          )
          .whenComplete(() => _programmaticScroll = false);
    } else {
      _scroll
          .animateTo(
            clamped,
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutBack,
          )
          .whenComplete(() => _programmaticScroll = false);
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _nudgeCycleTimer?.cancel();
    _replyAutoClose?.cancel();
    _springBackTimer?.cancel();
    _scroll.removeListener(_publish);
    _scroll.dispose();
    _glow.dispose();
    _ascent.dispose();
    _nudgePulse.dispose();
    _mist.dispose();
    _shake.dispose();
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
    final save = ref.read(gameSaveProvider);
    final focus = _computeFocus(built, save);
    final rung =
        built != null && index < built.length ? built.rungs[index] : null;
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

    // A Do rung whose game type is built opens it in the shared level shell.
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
    await _openRoute(
      rung,
      index,
      (_) => boardPack != null
          ? LearnBoardRunnerPage(
              rungId: rung.id,
              lessonId: lessonId,
              ladderIndex: index,
              pack: boardPack,
              muted: widget.muted,
            )
          : LearnRunnerPage(
              rungId: rung.id,
              lessonId: lessonId,
              ladderIndex: index,
              muted: widget.muted,
            ),
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

  _GiftFace _giftFace(
    _Station? station,
    int index,
    int focus,
    bool soon,
    GameSave save,
  ) {
    if (station != _Station.gift) return _GiftFace.none;
    final claimed = _stationClaimed(save, station!, ref.read(builtLadderProvider).value, index);
    if ((claimed || _seen.contains(index)) && !soon) return _GiftFace.opened;
    if (soon || index > focus) return _GiftFace.upcoming;
    if (index < focus) return _GiftFace.missed;
    return _GiftFace.active;
  }

  void _present(_Station station, int index, {required bool large}) {
    if (_flight != null || _reply != null || _sideChallenge != null) return;
    _springBackTimer?.cancel();
    if (MediaQuery.disableAnimationsOf(context)) {
      _openStation(station, index);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _flight = _Flight(index, station, large));
  }

  void _finishFlight() {
    final flight = _flight;
    if (!mounted || flight == null) return;
    setState(() => _flight = null);
    _openStation(flight.station, flight.index);
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

  void _closeSideChallenge() {
    if (_sideChallenge == null) return;
    unawaited(MascotSpeechLibrary.stop());
    setState(() => _sideChallenge = null);
    _armIdle();
    final built = ref.read(builtLadderProvider).value;
    final save = ref.read(gameSaveProvider);
    _scheduleAutoSpringBack(_computeFocus(built, save));
  }

  void _openStation(_Station station, int index) {
    HapticFeedback.lightImpact();
    final built = ref.read(builtLadderProvider).value;
    final save = ref.read(gameSaveProvider);
    final focus = _computeFocus(built, save);
    final openUpTo = dsPlayAllLevels ? _playableLadderSpan : focus + 2;

    if (!_isRungPlayable(index, built) || index > openUpTo) {
      ref.read(guideDirectorProvider.notifier).sayCue(
            MascotCueId.ladderComingSoon,
            speakVoice: true,
            muted: widget.muted,
          );
      _showKinetic(
        title: 'শীঘ্রই আসছে',
        body: 'আগের ধাপগুলো পার করলে এই সরঞ্জামটি খুলবে।',
        speak: false,
      );
      return;
    }
    setState(() => _seen.add(index));
    final asset = _assetFor(station, index);
    final challenge = MascotSpeechLibrary.challengeForSideItem(
      stationKind: station.name,
      propAsset: asset,
      ladderIndex: index,
    );
    ref.read(guideDirectorProvider.notifier).say(
          mood: challenge.mascotCue.mood,
          line: challenge.mascotCue.displayBn,
          gesture: challenge.mascotCue.gesture,
          voiceKey: challenge.mascotCue.voiceKey,
          speakVoice: true,
          muted: widget.muted,
        );
    setState(() {
      _sideChallenge = _ActiveSideChallenge(
        index: index,
        station: station,
        asset: asset,
        challenge: challenge,
        claimId: _stationClaimId(station, built, index),
        legacyClaimId: _stationLegacyClaimId(station, index),
      );
    });
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
      body: 'পথের শেষ। প্রতিটি ধাপে বাঁচার অভ্যাসই এই লক্ষ্য।',
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
        dsPlayAllLevels ? math.max(0, _playableLadderSpan - 1) : focus;
    final quiet = MediaQuery.disableAnimationsOf(context);
    final chromeBoot = ladderAsync.isLoading && built == null;

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
            final latestSave = ref.read(gameSaveProvider);
            final checkpoint =
                _legacyCheckpointIndex(latestSave.currentRungId, focus);
            if (checkpoint != focus) {
              unawaited(_softScrollToIndex(checkpoint));
            }
          },
          child: ScoreFlyHost(
            scoreKey: _scoreKey,
            child: Listener(
              onPointerDown: (_) {
                _activePointers++;
                _springBackTimer?.cancel();
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
                      child: child,
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
                          final station = cap || soon || fog ? null : _stationAt(i);
                          final claimed = station != null &&
                              _stationClaimed(save, station, built, i);
                          final rested = station != null &&
                              !soon &&
                              (claimed || i < focus || _seen.contains(i));
                          final fresh = station != null &&
                              !soon &&
                              !fog &&
                              !rested &&
                              station != _Station.gift;
                          final giftFace =
                              _giftFace(station, i, focus, soon, save);
                          // Read on scroll ticks by the prop's own builder.
                          double zoom() {
                            if (quiet || station == null) return 1.0;
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
                          return _MapBand(
                            index: i,
                            number: number,
                            soon: soon,
                            fog: fog,
                            cap: cap,
                            cleared: cleared,
                            current: !soon && !cap && i == focus,
                            locked: !cap && (soon || i > openUpTo),
                            glow: glow,
                            kind: rung?.kind ?? CatalogRungKind.doKind,
                            station: station,
                            fresh: fresh,
                            rested: rested,
                            claimed: claimed,
                            giftFace: giftFace,
                            zoom: zoom,
                            scroll: quiet ? null : _scroll,
                            hidden: _flight?.index == i,
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
                            onStation: station == null
                                ? null
                                : () {
                                    _clearNudge();
                                    _armIdle();
                                    _present(
                                      station,
                                      i,
                                      large: station == _Station.gift &&
                                          giftFace == _GiftFace.active,
                                    );
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
                  if (_flight != null)
                    Positioned.fill(
                      child: _ObjectReveal(
                        asset: _assetFor(_flight!.station, _flight!.index),
                        endScale: _flight!.large ? 2.2 : 1.45,
                        onDone: _finishFlight,
                      ),
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
                  if (_sideChallenge != null)
                    Positioned.fill(
                      child: _SideChallengeOverlay(
                        active: _sideChallenge!,
                        muted: widget.muted,
                        onClose: _closeSideChallenge,
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

  /// Catalog module id `mN` / rung `N.x/...` → first legacy bridge index of that module.
  int _legacyCheckpointIndex(String rungId, int fallback) {
    final match = RegExp(r'^(\d+)\.').firstMatch(rungId);
    if (match != null) {
      final module = int.tryParse(match.group(1)!) ?? 1;
      return ((module - 1) * 20).clamp(0, math.max(0, _playableLadderSpan - 1));
    }
    return (fallback ~/ 20) * 20;
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
          KeyedSubtree(
            key: deathKey,
            child: _ScoreChip(
              mark: '💀',
              value: enDigits('${save.deaths}'),
              color: calm ? SlmColors.emerald300 : SoftDanger.ink,
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
  final bool current;
  final bool locked;
  final Animation<double> glow;
  final CatalogRungKind kind;
  final _Station? station;
  final bool fresh;
  final bool rested;
  final bool claimed;
  final _GiftFace giftFace;
  final double Function() zoom;
  final ScrollController? scroll;
  final bool hidden;
  final bool motion;
  final Animation<double> light;
  final double journey;
  final bool idleNudge;
  final bool nudgeGift;
  final Animation<double> nudgePulse;
  final VoidCallback? onLevel;
  final VoidCallback? onStation;

  const _MapBand({
    required this.index,
    required this.number,
    required this.soon,
    required this.fog,
    required this.cap,
    required this.cleared,
    required this.current,
    required this.locked,
    required this.glow,
    required this.kind,
    required this.station,
    required this.fresh,
    required this.rested,
    required this.claimed,
    required this.giftFace,
    required this.zoom,
    required this.scroll,
    required this.hidden,
    required this.motion,
    required this.light,
    required this.journey,
    required this.idleNudge,
    required this.nudgeGift,
    required this.nudgePulse,
    required this.onLevel,
    required this.onStation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final rungY = h * 0.58;
        final gift = station == _Station.gift;
        final sideLeft = gift ? (index ~/ 8).isEven : index.isEven;
        final stationTop = gift
            ? const [0.0, 8.0, 16.0][(index ~/ 8) % 3]
            : 2.0 + (index % 3) * 4.0;
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
              if (station != null && !hidden)
                Positioned(
                  left: sideLeft ? 10 : null,
                  right: sideLeft ? null : 18,
                  top: stationTop,
                  width: 92,
                  height: 82,
                  child: _StationZoom(
                    scroll: scroll,
                    zoom: zoom,
                    child: _IdleNudgeHalo(
                      active:
                          idleNudge && nudgeGift && station == _Station.gift,
                      pulse: nudgePulse,
                      child: _StationPlaque(
                        station: station!,
                        asset: _assetFor(station!, index),
                        glow: glow,
                        fresh: fresh,
                        rested: rested,
                        claimed: claimed,
                        giftFace: giftFace,
                        motion: motion,
                        onTap: onStation,
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

/// Scales a station prop with the scroll position; only this transform
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

class _LevelCoin extends StatefulWidget {
  final int number;
  final bool soon;
  final bool cleared;
  final bool current;
  final bool locked;
  final CatalogRungKind kind;
  final bool motion;
  final VoidCallback? onTap;

  const _LevelCoin({
    required this.number,
    required this.soon,
    required this.cleared,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncLoops();
    });
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
    final quiet = !widget.motion || MediaQuery.disableAnimationsOf(context);
    final liveCurrent = widget.current && !widget.locked && !widget.soon;
    if (liveCurrent && !quiet) {
      if (!_breath.isAnimating) _breath.repeat(reverse: true);
      if (!_spin.isAnimating) _spin.repeat();
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
    final quiet = !widget.motion || MediaQuery.disableAnimationsOf(context);
    final live = !widget.locked && !widget.soon;
    if (!quiet && live && (widget.current || widget.cleared)) {
      _flash.forward(from: 0);
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bronze = widget.soon || (widget.locked && !widget.current);
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
        children: [
          Image.asset(
            asset,
            width: size,
            height: size,
            cacheWidth: 180,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
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

class _StationPlaque extends StatelessWidget {
  final _Station station;
  final String asset;
  final Animation<double> glow;
  final bool fresh;
  final bool rested;
  final bool claimed;
  final _GiftFace giftFace;
  final bool motion;
  final VoidCallback? onTap;

  const _StationPlaque({
    required this.station,
    required this.asset,
    required this.glow,
    required this.fresh,
    required this.rested,
    required this.claimed,
    required this.giftFace,
    required this.motion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chest = station == _Station.gift;
    final active = giftFace == _GiftFace.active;
    final missed = giftFace == _GiftFace.missed;
    final lively =
        motion && !claimed && (active || (giftFace == _GiftFace.none && fresh));
    double bob(double turn) => lively
        ? switch (station) {
            _Station.gift => -5 * turn,
            _Station.identify => -2.2 * turn,
            _Station.lesson => -1.6 * turn,
            _ => -1.2 * turn,
          }
        : 0.0;
    double tilt(double turn) =>
        motion && fresh && station == _Station.life ? (turn - 0.5) * 0.1 : 0.0;
    final picture = Image.asset(
      asset,
      width: 92,
      height: 82,
      cacheWidth: 280,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
    final dull = rested || giftFace == _GiftFace.opened;
    final art = missed
        ? ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.62, 0.2, 0.08, 0, 6,
              0.16, 0.55, 0.08, 0, 6,
              0.1, 0.16, 0.48, 0, 4,
              0, 0, 0, 1, 0,
            ]),
            child: picture,
          )
        : dull
            ? ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.55, 0.28, 0.12, 0, 10,
                  0.18, 0.52, 0.12, 0, 10,
                  0.12, 0.2, 0.48, 0, 8,
                  0, 0, 0, 1, 0,
                ]),
                child: picture,
              )
            : picture;

    Widget frame(double turn, Widget art) => Opacity(
      opacity: missed ? 0.78 : dull ? 0.72 : 1,
      child: Transform.translate(
        offset: Offset(0, bob(turn)),
        child: Transform.rotate(
          angle: tilt(turn),
          child: SizedBox(
            width: 92,
            height: 82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (active)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x66FFE7A3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xCCFFD56A)
                              .withValues(alpha: 0.55 + 0.35 * turn),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                art,
                if (station == _Station.hourly && fresh)
                  Align(
                    alignment: const Alignment(0, -0.16),
                    child: CustomPaint(
                      size: const Size(22, 22),
                      painter: _ClockPainter(turn),
                    ),
                  ),
                if (chest && motion && active)
                  CustomPaint(
                    size: const Size(92, 82),
                    painter: _SparkPainter(turn),
                  ),
                if (claimed)
                  Positioned(
                    right: 10,
                    bottom: 6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SlmColors.navy950,
                        border: Border.all(
                          color: SlmColors.emerald300,
                          width: 1.3,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: SlmColors.emerald300,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // Only a lively prop follows the glow clock, on its own layer; the rest
    // are built once.
    final body = lively
        ? RepaintBoundary(
            child: AnimatedBuilder(
              animation: glow,
              child: art,
              builder: (context, art) => frame(glow.value, art!),
            ),
          )
        : frame(0.2, art);

    return SlmTactile(
      onTap: onTap,
      builder: (context, press, child) =>
          Transform.scale(scale: 1 - 0.05 * press, child: child),
      child: body,
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

class _ObjectReveal extends StatefulWidget {
  final String asset;
  final double endScale;
  final VoidCallback onDone;

  const _ObjectReveal({
    required this.asset,
    required this.endScale,
    required this.onDone,
  });

  @override
  State<_ObjectReveal> createState() => _ObjectRevealState();
}

class _ObjectRevealState extends State<_ObjectReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    _move.forward().whenComplete(() async {
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _move,
      builder: (context, _) {
        final t = Curves.easeOutBack.transform(_move.value.clamp(0.0, 1.0));
        final scale = 0.22 + (widget.endScale - 0.22) * t;
        return Stack(
          children: [
            ModalBarrier(
              color: Colors.black.withValues(alpha: 0.5 * t.clamp(0.0, 1.0)),
              dismissible: false,
            ),
            Center(
              child: Transform.translate(
                offset: Offset(0, (1 - t.clamp(0.0, 1.0)) * 120),
                child: Transform.scale(
                  scale: scale,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD56A)
                              .withValues(alpha: 0.18 + 0.45 * t.clamp(0.0, 1.0)),
                          blurRadius: widget.endScale > 1.8 ? 34 : 18,
                          spreadRadius: 2 * t.clamp(0.0, 1.0),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      widget.asset,
                      width: 96,
                      height: 84,
                      cacheWidth: 320,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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

class _SparkPainter extends CustomPainter {
  final double turn;

  const _SparkPainter(this.turn);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromRGBO(255, 236, 180, 0.25 + 0.55 * turn);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.18), 1.4, paint);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.28), 1.1, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.turn != turn;
}

class _ClockPainter extends CustomPainter {
  final double turn;

  const _ClockPainter(this.turn);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawLine(
      c,
      c +
          Offset(
            math.cos(turn * math.pi * 2 - 1.2) * 7,
            math.sin(turn * math.pi * 2 - 1.2) * 7,
          ),
      Paint()
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF1A2744),
    );
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) =>
      oldDelegate.turn != turn;
}

/// Interactive in-ladder overlay for touchable side items (_Station props)
/// that awards live ◆ points into the top HUD and speaks with the Game Mascot.
class _SideChallengeOverlay extends ConsumerStatefulWidget {
  final _ActiveSideChallenge active;
  final bool muted;
  final VoidCallback onClose;

  const _SideChallengeOverlay({
    required this.active,
    required this.muted,
    required this.onClose,
  });

  @override
  ConsumerState<_SideChallengeOverlay> createState() =>
      _SideChallengeOverlayState();
}

class _SideChallengeOverlayState extends ConsumerState<_SideChallengeOverlay> {
  int? _pickedOption;
  bool _completed = false;

  String get _claimKey => widget.active.claimId;

  bool _claimedIn(GameSave save) =>
      save.giftsClaimed.contains(_claimKey) || save.giftsClaimed.contains(widget.active.legacyClaimId);

  bool get _alreadyClaimed => _claimedIn(ref.read(gameSaveProvider));

  Future<void> _onCheckTap(Offset globalOrigin) async {
    if (_completed) {
      widget.onClose();
      return;
    }
    final ch = widget.active.challenge;
    final firstTime = !_alreadyClaimed;
    setState(() => _completed = true);
    if (firstTime) {
      await ref.read(gameSaveProvider.notifier).claimGift(_claimKey);
      await BeatFx.scoreDelta(
        ref,
        ch.points,
        mood: GuideMood.celebrate,
        originGlobal: globalOrigin,
        muted: widget.muted,
      );
    }
    ref.read(guideDirectorProvider.notifier).say(
          mood: GuideMood.celebrate,
          line: ch.rewardNoteBn,
          voiceKey: 'ds_exp_right_1',
          speakVoice: true,
          muted: widget.muted,
        );
  }

  Future<void> _onOptionTap(int index, Offset globalOrigin) async {
    if (_completed) return;
    final ch = widget.active.challenge;
    final ok = index == ch.correctIndex;
    setState(() {
      _pickedOption = index;
      if (ok) _completed = true;
    });
    if (ok) {
      final firstTime = !_alreadyClaimed;
      if (firstTime) {
        await ref.read(gameSaveProvider.notifier).claimGift(_claimKey);
        await BeatFx.scoreDelta(
          ref,
          ch.points,
          mood: GuideMood.celebrate,
          originGlobal: globalOrigin,
          muted: widget.muted,
        );
      }
      ref.read(guideDirectorProvider.notifier).say(
            mood: GuideMood.celebrate,
            line: ch.rewardNoteBn,
            voiceKey: 'ds_exp_right_1',
            speakVoice: true,
            muted: widget.muted,
          );
    } else {
      await BeatFx.scoreDelta(
        ref,
        -5,
        mood: GuideMood.warn,
        originGlobal: globalOrigin,
        muted: widget.muted,
      );
      ref.read(guideDirectorProvider.notifier).say(
            mood: GuideMood.warn,
            line: ch.wrongFeedbackBn ?? 'আরেকবার ভেবে সঠিক উত্তরটি বেছে নিন!',
            voiceKey: 'ds_wrong_bhabun',
            speakVoice: true,
            muted: widget.muted,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ch = widget.active.challenge;
    final claimed = _claimedIn(ref.watch(gameSaveProvider));

    return ColoredBox(
      color: const Color(0xCC040914),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF15243E), Color(0xFF0A1324)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color:
                        _completed ? SlmColors.emerald400 : SlmColors.gold400,
                    width: 1.6,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xAA000000),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: SlmColors.gold400.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: SlmColors.gold400.withValues(alpha: 0.55),
                              ),
                            ),
                            child: Text(
                              enDigits(ch.badgeBn),
                              style: zlText(
                                12,
                                weight: FontWeight.w800,
                                color: SlmColors.gold300,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: widget.onClose,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: SlmColors.ivory,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: SizedBox(
                          width: 84,
                          height: 84,
                          child: Image.asset(
                            widget.active.asset,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        enDigits(ch.titleBn),
                        textAlign: TextAlign.center,
                        style: zlText(
                          20,
                          weight: FontWeight.w900,
                          color: SlmColors.ivory,
                          height: 1.22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        enDigits(ch.bodyBn),
                        textAlign: TextAlign.center,
                        style: zlText(
                          15,
                          weight: FontWeight.w600,
                          color: const Color(0xFFD6E0F0),
                          height: 1.38,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (ch.isQuiz) ...[
                        for (var i = 0; i < ch.optionsBn!.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          Builder(
                            builder: (_) {
                              final selected = _pickedOption == i;
                              final isRight = i == ch.correctIndex;
                              final showRight = _completed && isRight;
                              final showWrong = selected && !isRight;
                              return GestureDetector(
                                onTapDown: (d) =>
                                    _onOptionTap(i, d.globalPosition),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: showRight
                                        ? const Color(0xFF0F3D2C)
                                        : showWrong
                                            ? const Color(0xFF3E161B)
                                            : const Color(0xFF1D2E4D),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: showRight
                                          ? SlmColors.emerald300
                                          : showWrong
                                              ? SoftDanger.ink
                                              : SlmColors.gold400
                                                  .withValues(alpha: 0.45),
                                      width: 1.4,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        showRight
                                            ? Icons.check_circle_rounded
                                            : showWrong
                                                ? Icons.cancel_rounded
                                                : Icons.bolt_rounded,
                                        size: 20,
                                        color: showRight
                                            ? SlmColors.emerald300
                                            : showWrong
                                                ? SoftDanger.ink
                                                : SlmColors.gold300,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          enDigits(ch.optionsBn![i]),
                                          style: zlText(
                                            14.5,
                                            weight: FontWeight.w700,
                                            color: SlmColors.ivory,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ] else ...[
                        GestureDetector(
                          onTapDown: (d) => _onCheckTap(d.globalPosition),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _completed
                                    ? const [
                                        Color(0xFF124634),
                                        Color(0xFF0B2B20),
                                      ]
                                    : const [
                                        Color(0xFFF3C969),
                                        Color(0xFFD4A037),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: _completed
                                    ? SlmColors.emerald300
                                    : SlmColors.gold200,
                                width: 1.4,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _completed
                                      ? Icons.verified_rounded
                                      : Icons.touch_app_rounded,
                                  size: 20,
                                  color: _completed
                                      ? SlmColors.emerald300
                                      : SlmColors.navy950,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _completed
                                        ? enDigits(ch.rewardNoteBn)
                                        : enDigits(
                                            claimed
                                                ? 'আবার যাচাই করুন'
                                                : ch.checkActionBn,
                                          ),
                                    textAlign: TextAlign.center,
                                    style: zlText(
                                      14.5,
                                      weight: FontWeight.w900,
                                      color: _completed
                                          ? SlmColors.emerald300
                                          : SlmColors.navy950,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_completed) ...[
                        const SizedBox(height: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: SlmColors.gold400,
                            foregroundColor: SlmColors.navy950,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: widget.onClose,
                          child: Text(
                            'মইয়ে ফিরুন',
                            style: zlText(
                              15,
                              weight: FontWeight.w900,
                              color: SlmColors.navy950,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Center(
                        child: AiLinemanGuide(
                          sprite: 88,
                          bubbleWidth: 268,
                          showBubble: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
