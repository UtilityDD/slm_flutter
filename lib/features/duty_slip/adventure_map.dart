import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_sheet.dart';
import '../admin/dev_unlock.dart';
import '../game/beat_fx.dart';
import '../game/content_catalog.dart';
import '../game/game_save.dart';
import '../game/ladder_builder.dart';
import '../game/learn_runner.dart';
import '../guide/guide_director.dart';
import '../guide/ladder_guide_host.dart';
import '../home/lesson_progress_store.dart';
import '../home/lineman_progress.dart';
import '../quizzes/identify_quiz_screen.dart';
import '../quizzes/quiz_play_screen.dart';
import '../shell/shell_providers.dart';
import '../training/training_provider.dart';
import '../training/training_screen.dart';
import '../zero_loss/zero_loss_fx.dart';
import '../zero_loss/zero_loss_ui.dart';
import 'adventure_scenery.dart';
import 'duty_slip_engine.dart';
import 'duty_slip_voice.dart';

/// Monumental golden ladder shell.
/// Rung count + kinds come from [builtLadderProvider] (327). Module 1 Learn
/// rungs open the Learn runner; Do/gate still use the [dsLevels] bridge until
/// the Do wire lands.
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

enum _GiftFace { none, missed, active, upcoming, opened }

class _Flight {
  final int index;
  final _Station station;
  final bool large;

  const _Flight(this.index, this.station, this.large);
}

/// Which ladder object the idle nudge is pointing at.
class _Nudge {
  final int index;
  final bool gift;

  const _Nudge(this.index, this.gift);
}

class _Reply {
  final String title;
  final String body;

  const _Reply(this.title, this.body);
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

class _AdventureMapState extends ConsumerState<AdventureMap> with TickerProviderStateMixin {
  static const _rowH = 108.0;
  /// Emerald cap sits above the last catalog rung.
  static const _emeraldExtra = 1;

  /// Legacy bridge: catalog is Coming Soon until Module 1 fill; keep old levels playable.
  bool _bridgePlayable(int index) => index >= 0 && index < dsLevels.length;

  int _ladderLen(BuiltLadder? built) => built?.length ?? math.max(dsLevels.length, 40);

  final _scoreKey = GlobalKey();
  final _deathKey = GlobalKey();
  final _scroll = ScrollController();
  final _seen = <int>{};
  _Flight? _flight;
  _Reply? _reply;
  Timer? _replyAutoClose;
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
  /// Current idle-nudge target. Only the halo of that one coin/gift listens,
  /// so moving the nudge never rebuilds the ladder.
  final _nudge = ValueNotifier<_Nudge?>(null);
  /// Nudge cycles shown this idle period: level → gift → level, then stop
  /// until the player touches the ladder again.
  static const _nudgeMaxCycles = 3;
  var _nudgeCycles = 0;
  var _nudgeOnGiftTurn = false;
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

  /// Glow and gleam loop only while looping motion is allowed. TickerMode
  /// already mutes them when another route covers the ladder.
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
    _clearNudge();
    _armIdle();
    final guide = ProviderScope.containerOf(context).read(guideDirectorProvider);
    if (guide.mood == GuideMood.sleep) {
      ProviderScope.containerOf(context).read(guideDirectorProvider.notifier).wake();
    }
  }

  void _clearNudge() {
    _nudgeCycleTimer?.cancel();
    _nudgeCycleTimer = null;
    if (_nudgePulse.isAnimating) _nudgePulse.stop();
    _nudge.value = null;
  }

  void _armIdle() {
    _nudgeCycles = 0;
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 14), () {
      if (!mounted) return;
      _startIdleNudge();
    });
  }

  /// Gift chests currently on-screen (any face except opened).
  List<int> _visibleGiftIndices() {
    if (!_scroll.hasClients) return const [];
    final built = ref.read(builtLadderProvider).value;
    final live = math.min(_ladderLen(built), dsLevels.length);
    final focus = widget.engine.unlocked.clamp(0, math.max(0, live - 1)).toInt();
    final view = _scroll.position.viewportDimension;
    final scrolled = _scroll.offset;
    final bottomInset = MediaQuery.paddingOf(context).bottom + 18;
    final out = <int>[];
    for (var i = 0; i < live; i++) {
      if (_stationAt(i) != _Station.gift) continue;
      final soon = !_bridgePlayable(i);
      final face = _giftFace(_Station.gift, i, focus, soon);
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
    // Already comfortably on screen — don't move (avoids fighting the pulse).
    if (fromBottom > view * 0.18 && fromBottom < view * 0.82) return;
    final want = (index * _rowH) - (view * 0.28);
    final clamped = want.clamp(0.0, _scroll.position.maxScrollExtent);
    _programmaticScroll = true;
    try {
      await _scroll.animateTo(clamped, duration: const Duration(milliseconds: 520), curve: Curves.easeOutCubic);
    } finally {
      _programmaticScroll = false;
    }
  }

  void _applyNudgeTarget({required bool giftTurn}) {
    if (!mounted) return;
    final built = ref.read(builtLadderProvider).value;
    final live = math.min(_ladderLen(built), dsLevels.length);
    final focus = widget.engine.unlocked.clamp(0, math.max(0, live - 1)).toInt();
    final gifts = _visibleGiftIndices();
    late final int target;
    late final bool asGift;
    if (giftTurn && gifts.isNotEmpty) {
      // Prefer a different gift than last time when possible.
      final pool = gifts.length == 1
          ? gifts
          : gifts.where((g) => g != _nudge.value?.index).toList(growable: false);
      final pick = pool.isEmpty ? gifts : pool;
      target = pick[_nudgeRng.nextInt(pick.length)];
      asGift = true;
    } else {
      target = focus;
      asGift = false;
    }
    _nudgeCycles++;
    _nudge.value = _Nudge(target, asGift);
    unawaited(_softScrollToIndex(target));
    ProviderScope.containerOf(context).read(guideDirectorProvider.notifier).nudgePlay(gift: asGift);
    // One sound per idle period, not one every cycle.
    if (!widget.muted && _nudgeCycles == 1) {
      unawaited(ZlFx.cue(
        asGift ? 'sounds/intro/glass.ogg' : 'sounds/intro/confirm.ogg',
        volume: 0.4,
        muted: false,
      ));
    }
  }

  void _startIdleNudge() {
    if (!mounted || !slmLoopsOn(context)) return;
    if (_flight != null || _reply != null) return;
    if (_nudge.value != null) return;
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
    // Alternate: level → random visible gift → level → …
    _nudgeCycleTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _nudge.value == null) return;
      if (_nudgeCycles >= _nudgeMaxCycles || !_ladderVisible()) {
        // Done for this idle period; the next touch re-arms it.
        _clearNudge();
        return;
      }
      _nudgeOnGiftTurn = !_nudgeOnGiftTurn;
      // If no gift on screen, stay on the active level (still speak/sound).
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
    if (widget.scrollOut.value != _scroll.offset) widget.scrollOut.value = _scroll.offset;
  }

  void _pin({bool initial = false}) {
    if (!mounted || !_scroll.hasClients) return;
    final view = _scroll.position.viewportDimension;
    final target = (widget.engine.unlocked * _rowH) - (view * 0.22);
    final clamped = target.clamp(0.0, _scroll.position.maxScrollExtent);
    if (initial) {
      _scroll.jumpTo(0);
      _scroll.animateTo(clamped, duration: const Duration(milliseconds: 850), curve: Curves.easeOutCubic);
    } else {
      _scroll.animateTo(clamped, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _nudgeCycleTimer?.cancel();
    _replyAutoClose?.cancel();
    _scroll.removeListener(_publish);
    _scroll.dispose();
    _glow.dispose();
    _ascent.dispose();
    _nudgePulse.dispose();
    _nudge.dispose();
    _mist.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _openLevel(int index, {BuiltLadder? built}) {
    _clearNudge();
    _armIdle();
    final rung = built != null && index < built.length ? built.rungs[index] : null;
    final locked = !dsPlayAllLevels && index > widget.engine.unlocked;
    if (locked) {
      // Design: rung above → shake + mist, no text.
      _pulseMist(shake: true);
      return;
    }

    // Catalog Learn (playable) opens the swipe runner — never a fall path.
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

    final soon = (rung?.isComingSoon ?? true) && !_bridgePlayable(index);
    if (soon) {
      _hintComingSoon();
      return;
    }
    if (!_bridgePlayable(index)) {
      _hintComingSoon();
      return;
    }
    final spec = dsLevels[index];
    if (gameNeedsVerifyNow(context, spec.number)) {
      showVerifySheet(context);
      return;
    }
    HapticFeedback.selectionClick();
    unawaited(ref.read(gameSaveProvider.notifier).setCurrentRung(rung?.id ?? '${spec.number}'));
    widget.onOpen(index);
  }

  Future<void> _openLearn(BuiltRung rung, int index) async {
    final lessonId = rung.lesson?.id ?? rung.def.lessonId ?? '';
    if (lessonId.isEmpty) {
      _hintComingSoon();
      return;
    }
    final cleared = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LearnRunnerPage(
          rungId: rung.id,
          lessonId: lessonId,
          ladderIndex: index,
          muted: widget.muted,
        ),
      ),
    );
    if (!mounted) return;
    if (cleared == true) {
      widget.engine.unlockThrough(index + 1);
      setState(() {});
      unawaited(_softScrollToIndex(index + 1));
    }
  }

  bool _scrolledAwayFromFocus(int focus) {
    if (!_scroll.hasClients || !_scroll.position.hasViewportDimension) return false;
    final view = _scroll.position.viewportDimension;
    final scrolled = _scroll.offset;
    final bottomInset = MediaQuery.paddingOf(context).bottom + 18;
    final fromBottom = bottomInset + focus * _rowH + _rowH / 2 - scrolled;
    return fromBottom < view * 0.12 || fromBottom > view * 0.88;
  }

  void _pulseMist({required bool shake}) {
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
  }

  _GiftFace _giftFace(_Station? station, int index, int focus, bool soon) {
    if (station != _Station.gift) return _GiftFace.none;
    if (_seen.contains(index) && !soon) return _GiftFace.opened;
    if (soon || index > focus) return _GiftFace.upcoming;
    if (index < focus) return _GiftFace.missed;
    return _GiftFace.active;
  }

  void _present(_Station station, int index, {required bool large}) {
    if (_flight != null || _reply != null) return;
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

  void _showKinetic({required String title, required String body, required bool speak}) {
    if (speak && !widget.muted) unawaited(DsVoice.play(body, muted: false));
    if (!mounted) return;
    _replyAutoClose?.cancel();
    setState(() => _reply = _Reply(title, enDigits(body)));
    _replyAutoClose = Timer(const Duration(milliseconds: 3200), () {
      if (!mounted || _reply == null) return;
      setState(() => _reply = null);
      _armIdle();
    });
  }

  void _closeKinetic() {
    _replyAutoClose?.cancel();
    if (_reply == null) return;
    setState(() => _reply = null);
    _armIdle();
  }

  void _openStation(_Station station, int index) {
    HapticFeedback.lightImpact();
    if (index >= dsLevels.length) {
      _showKinetic(
        title: 'শীঘ্রই আসছে',
        body: 'এই ধাপটি এখনো খোলেনি।',
        speak: false,
      );
      return;
    }
    setState(() => _seen.add(index));
    final guide = ProviderScope.containerOf(context).read(guideDirectorProvider.notifier);
    switch (station) {
      case _Station.hourly:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const QuizPlayScreen()));
      case _Station.identify:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const IdentifyQuizScreen()));
      case _Station.lesson:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TrainingScreen()));
      case _Station.tips || _Station.life:
        guide.react(GuideMood.inspire);
        _showKinetic(
          title: station == _Station.tips ? 'নিরাপত্তা টিপস' : 'লাইফ স্কিল',
          body: dsBriefFor(dsLevels[index]).body,
          speak: true,
        );
      case _Station.gift:
        guide.react(GuideMood.glad);
        unawaited(ProviderScope.containerOf(context).read(gameSaveProvider.notifier).claimGift('ladder_$index'));
        _showKinetic(
          title: 'সারপ্রাইজ গিফট',
          body: 'পরের ধাপগুলো খুললে এই বক্সে বিশেষ চ্যালেঞ্জ পাবেন।',
          speak: false,
        );
    }
  }

  void _hintComingSoon() {
    _clearNudge();
    _pulseMist(shake: false);
    _showKinetic(
      title: 'শীঘ্রই আসছে',
      body: 'এই ধাপটি এখনো খোলেনি।',
      speak: false,
    );
  }

  void _hintEmerald() {
    _clearNudge();
    HapticFeedback.selectionClick();
    ProviderScope.containerOf(context).read(guideDirectorProvider.notifier).react(GuideMood.inspire);
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
    final bridgeLive = math.min(catalogLen, dsLevels.length);
    // Achieved progress (always pin here). Developer mode opens every bridge rung.
    final focus = e.unlocked.clamp(0, math.max(0, bridgeLive - 1)).toInt();
    final openUpTo = dsPlayAllLevels ? math.max(0, bridgeLive - 1) : focus;
    ref.watch(devUnlockProvider); // rebuild lock chrome when admin toggles Developer
    final quiet = MediaQuery.disableAnimationsOf(context);
    final save = ref.watch(gameSaveProvider);
    final chromeBoot = ladderAsync.isLoading && built == null;

    // Always bring the player to their achieved rung when the catalog settles.
    ref.listen(builtLadderProvider, (prev, next) {
      if (next.hasValue && !(prev?.hasValue ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _pin(initial: true);
        });
      }
    });

    // Nothing here listens to an animation: the ladder, header and guide are
    // built on state changes only. Each moving piece (coin glow, gleam on the
    // rails, prop zoom, nudge halo, mist, shake) has its own small listener.
    final Animation<double> glow = quiet ? const AlwaysStoppedAnimation(0.6) : _glow;
    final Animation<double> light = quiet ? const AlwaysStoppedAnimation(0.35) : _ascent;
    final journey = itemCount * _rowH;
    final topInset = MediaQuery.paddingOf(context).top + 58;
    final bottomInset = MediaQuery.paddingOf(context).bottom + 18;
    final list = NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (_programmaticScroll) return false;
        if (n is ScrollUpdateNotification && n.dragDetails != null) {
          _onFingerScroll();
        } else if (n is ScrollStartNotification && n.dragDetails != null) {
          _onFingerScroll();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.vertical,
        reverse: true,
        physics: const ClampingScrollPhysics(),
        clipBehavior: Clip.hardEdge,
        itemCount: itemCount,
        itemExtent: _rowH,
        padding: EdgeInsets.only(top: topInset, bottom: bottomInset + 18),
        itemBuilder: (context, i) {
          final cap = i == catalogLen;
          final rung = !cap && built != null && i < built.length ? built.rungs[i] : null;
          final soon = !cap && ((rung?.isComingSoon ?? true) && !_bridgePlayable(i));
          final fog = !cap && i > focus + 3;
          final station = cap || soon ? null : _stationAt(i);
          final rested = station != null && !soon && (i < focus || _seen.contains(i));
          final fresh = station != null && !soon && !fog && !rested && station != _Station.gift;
          final giftFace = _giftFace(station, i, focus, soon);
          final number = cap ? catalogLen : (rung?.number ?? (i + 1));
          final learnCleared = rung != null && save.rungProgress[rung.id] == 'cleared';
          final bridgeCleared = _bridgePlayable(i) &&
              (i < focus || (e.bestRank[i] != null && e.bestRank[i] != DsLevelRank.again));
          final cleared = !soon && !cap && (learnCleared || bridgeCleared);
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
            giftFace: giftFace,
            scroll: _scroll,
            bottomInset: bottomInset,
            hidden: _flight?.index == i,
            motion: !quiet,
            light: light,
            journey: journey,
            nudge: _nudge,
            nudgePulse: _nudgePulse,
            onLevel: cap
                ? _hintEmerald
                : soon
                    ? _hintComingSoon
                    : () => _openLevel(i, built: built),
            onStation: station == null
                ? null
                : () {
                    _clearNudge();
                    _armIdle();
                    _present(
                      station,
                      i,
                      large: station == _Station.gift && giftFace == _GiftFace.active,
                    );
                  },
          );
        },
      ),
    );
    return DeathMomentHost(
      deathKey: _deathKey,
      onSettled: () {
        final save = ref.read(gameSaveProvider);
        final checkpoint = _legacyCheckpointIndex(save.currentRungId, focus);
        if (checkpoint != focus) {
          unawaited(_softScrollToIndex(checkpoint));
        }
      },
      child: ScoreFlyHost(
        scoreKey: _scoreKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: AdventureWorld(scroll: _scroll, drift: _ascent, motion: !quiet),
              ),
            ),
            AnimatedBuilder(
              animation: _shake,
              child: list,
              builder: (context, child) {
                final shakeX = quiet ? 0.0 : math.sin(_shake.value * math.pi * 6) * 5 * (1 - _shake.value);
                return Transform.translate(offset: Offset(shakeX, 0), child: child);
              },
            ),
            if (chromeBoot)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: SlmColors.gold300),
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
                            (_mist.value < 0.45 ? _mist.value / 0.45 : (1 - _mist.value) / 0.55).clamp(0.0, 1.0));
                    if (mistT <= 0.01) return const SizedBox.shrink();
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.1),
                          radius: 1.15,
                          colors: [
                            const Color(0x33D7E4F5).withValues(alpha: 0.18 * mistT),
                            const Color(0x99A8B8CC).withValues(alpha: 0.42 * mistT),
                            const Color(0xCC050A16).withValues(alpha: 0.55 * mistT),
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
                    colors: [Color(0x66050A16), Color(0x00050A16)],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
                  child: _TopHeader(
                    engine: e,
                    scoreKey: _scoreKey,
                    deathKey: _deathKey,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ),
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
            Positioned(
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 14,
              child: AnimatedBuilder(
                animation: _scroll,
                builder: (context, _) {
                  if (!_scrolledAwayFromFocus(focus)) return const SizedBox.shrink();
                  return _MeChip(
                    onTap: () {
                      _clearNudge();
                      unawaited(_softScrollToIndex(focus));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Catalog module id `mN` / rung `N.x/...` → first legacy bridge index of that module.
  int _legacyCheckpointIndex(String rungId, int fallback) {
    final match = RegExp(r'^(\d+)\.').firstMatch(rungId);
    if (match != null) {
      final module = int.tryParse(match.group(1)!) ?? 1;
      return ((module - 1) * 20).clamp(0, math.max(0, dsLevels.length - 1));
    }
    return (fallback ~/ 20) * 20;
  }
}

class _MeChip extends StatelessWidget {
  final VoidCallback onTap;

  const _MeChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SlmTactile(
      onTap: onTap,
      semanticLabel: 'আমি',
      builder: (context, press, child) => Transform.scale(scale: 1 - 0.06 * press, child: child),
        child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xE6050A16),
          border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.55)),
        ),
        child: Text('আমি', style: zlText(13, weight: FontWeight.w800, color: SlmColors.gold200, height: 1)),
      ),
    );
  }
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
        boxShadow: const [BoxShadow(color: Color(0x8C000000), blurRadius: 8, offset: Offset(0, 3))],
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
    final rankLevel = rankFromSave > 0 ? rankFromSave : (path.achieved == 0 ? 1 : path.achieved);
    final rank = linemanBadgeName(rankLevel, bn);
    final calm = save.deaths == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          _CircleIcon(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 10),
          _RankPill(label: rank),
          const Spacer(),
          KeyedSubtree(
            key: scoreKey,
            child: _ScoreChip(mark: '◆', value: enDigits('${save.points}'), color: SlmColors.gold200),
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

  const _RankPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.45)),
        color: const Color(0xB3050A16),
      ),
      child: Text(label, style: zlText(12, weight: FontWeight.w800, color: SlmColors.gold200, height: 1.1)),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String mark;
  final String value;
  final Color color;

  const _ScoreChip({required this.mark, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xB3050A16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text('$mark  $value', style: zlText(14, weight: FontWeight.w800, color: color, height: 1.1)),
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
      builder: (context, press, child) => Transform.scale(scale: 1 - 0.06 * press, child: child),
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
  final _GiftFace giftFace;
  final ScrollController scroll;
  final double bottomInset;
  final bool hidden;
  final bool motion;
  final Animation<double> light;
  final double journey;
  final ValueListenable<_Nudge?> nudge;
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
    required this.giftFace,
    required this.scroll,
    required this.bottomInset,
    required this.hidden,
    required this.motion,
    required this.light,
    required this.journey,
    required this.nudge,
    required this.nudgePulse,
    required this.onLevel,
    required this.onStation,
  });

  /// Prop zoom by distance from the middle of the viewport.
  double _zoom() {
    if (!motion || station == null) return 1.0;
    final laidOut = scroll.hasClients && scroll.position.hasViewportDimension;
    final view = laidOut ? scroll.position.viewportDimension : 640.0;
    final scrolled = scroll.hasClients ? scroll.offset : 0.0;
    const rowH = _AdventureMapState._rowH;
    final fromBottom = bottomInset + index * rowH + rowH / 2 - scrolled;
    final dist = (((view - fromBottom) / view) - 0.5).abs().clamp(0.0, 0.5) * 2;
    final closeness = 1 - dist;
    return 0.34 + 1.2 * closeness * closeness;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final rungY = h * 0.58;
        final gift = station == _Station.gift;
        final sideLeft = gift ? (index ~/ 8).isEven : index.isEven;
        final stationTop = gift ? const [0.0, 8.0, 16.0][(index ~/ 8) % 3] : 2.0 + (index % 3) * 4.0;
        final gleam = CustomPaint(
          size: Size(w, h),
          painter: _RailGleamPainter(index: index, light: light, journey: journey, height: h),
        );

        if (cap) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                size: Size(w, h),
                painter: const _GoldenLadderPainter(fog: false, cap: true),
              ),
              gleam,
              Center(
                child: _FinishMark(glow: glow, motion: motion, onTap: onLevel),
              ),
            ],
          );
        }

        return Opacity(
          opacity: fog ? 0.42 : 1,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(w, h),
                painter: _GoldenLadderPainter(fog: fog),
              ),
              gleam,
              Positioned(
                left: w / 2 - (current ? (kind == CatalogRungKind.gate ? 34 : 30) : (kind == CatalogRungKind.gate ? 28 : 24)),
                top: rungY - (current ? (kind == CatalogRungKind.gate ? 34 : 30) : (kind == CatalogRungKind.gate ? 28 : 24)),
                width: current ? (kind == CatalogRungKind.gate ? 68 : 60) : (kind == CatalogRungKind.gate ? 56 : 48),
                height: current ? (kind == CatalogRungKind.gate ? 68 : 60) : (kind == CatalogRungKind.gate ? 56 : 48),
                child: _IdleNudgeHalo(
                  index: index,
                  gift: false,
                  nudge: nudge,
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
              if (station != null && !hidden)
                Positioned(
                  left: sideLeft ? 4 : null,
                  right: sideLeft ? null : 4,
                  top: stationTop,
                  width: 96,
                  height: 84,
                  child: _StationZoom(
                    scroll: motion ? scroll : null,
                    zoom: _zoom,
                    child: _IdleNudgeHalo(
                      index: index,
                      gift: true,
                      enabled: station == _Station.gift,
                      nudge: nudge,
                      pulse: nudgePulse,
                      child: _StationPlaque(
                        station: station!,
                        asset: _assetFor(station!, index),
                        glow: glow,
                        fresh: fresh,
                        rested: rested,
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

/// Scales a station prop with the scroll position; only this transform
/// rebuilds while the ladder scrolls.
class _StationZoom extends StatelessWidget {
  final ScrollController? scroll;
  final double Function() zoom;
  final Widget child;

  const _StationZoom({required this.scroll, required this.zoom, required this.child});

  @override
  Widget build(BuildContext context) {
    final s = scroll;
    if (s == null) {
      return Transform.scale(scale: zoom(), alignment: Alignment.center, child: child);
    }
    return AnimatedBuilder(
      animation: s,
      child: child,
      builder: (context, child) => Transform.scale(scale: zoom(), alignment: Alignment.center, child: child),
    );
  }
}

class _IdleNudgeHalo extends StatelessWidget {
  final int index;
  final bool gift;
  final bool enabled;
  final ValueListenable<_Nudge?> nudge;
  final Animation<double> pulse;
  final Widget child;

  const _IdleNudgeHalo({
    required this.index,
    required this.gift,
    this.enabled = true,
    required this.nudge,
    required this.pulse,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ValueListenableBuilder<_Nudge?>(
      valueListenable: nudge,
      child: child,
      builder: (context, n, child) {
        final active = n != null && n.index == index && n.gift == gift;
        if (!active) return child!;
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
                    painter: _NudgeRingPainter(progress: pulse, color: SlmColors.gold300),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: pulse,
              child: child,
              builder: (context, child) {
                final t = pulse.value.clamp(0.0, 1.0);
                // Zoom the child only — rings paint outside without shifting layout.
                final scale = 1.0 + 0.14 * math.sin(t * math.pi * 2);
                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                  child: child,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _NudgeRingPainter extends CustomPainter {
  final Animation<double> progress;
  final Color color;

  _NudgeRingPainter({required this.progress, required this.color}) : super(repaint: progress);

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

  _RailGleamPainter({required this.index, required this.light, required this.journey, required this.height})
      : super(repaint: _GleamGate(light, (v) => _inBand(_gleamY(v, index, journey), height)));

  static double _gleamY(double v, int index, double journey) {
    const rowH = _AdventureMapState._rowH;
    return rowH - (v * journey - index * rowH);
  }

  static bool _inBand(double gleamY, double h) => gleamY > -28 && gleamY < h + 28;

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
      old.index != index || old.light != light || old.journey != journey || old.height != height;
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
      RRect.fromRectAndRadius(Rect.fromLTRB(leftX - 8, 0, rightX + 12, h), const Radius.circular(12)),
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
    canvas.drawRRect(body.shift(const Offset(2.4, 0)), Paint()..color = const Color(0xFF3A280C));
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
      RRect.fromRectAndRadius(rung.shift(const Offset(1.6, 3)), const Radius.circular(4)),
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
              : const [Color(0xFFFFF8DC), Color(0xFFE6C56E), Color(0xFF8C6822), Color(0xFF4A3410)],
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
      canvas.drawCircle(Offset(x - 0.8, y - 0.9), 1.15, Paint()..color = const Color(0xFFB6FFD8));
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
    _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 5200));
    _flash = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
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
              shadows: const [Shadow(color: Color(0xDD000000), offset: Offset(0, 1.2), blurRadius: 2)],
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
        final flashOut = flash < 0.55 ? (flash / 0.55) : (1 - (flash - 0.55) / 0.45).clamp(0.0, 1.0);

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
                          color: SlmColors.gold300.withValues(alpha: 0.22 + 0.28 * breath),
                          blurRadius: 14 + 10 * breath,
                          spreadRadius: 1 + 2 * breath,
                        ),
                        BoxShadow(
                          color: SlmColors.emerald400.withValues(alpha: 0.14 + 0.12 * breath),
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
                        color: (current ? SlmColors.gold300 : SlmColors.gold200).withValues(alpha: 0.8 * flashOut),
                        width: current ? 2.4 : 1.6,
                      ),
                    ),
                  ),
                face!,
              ],
            ),
          ),
        );

        if (current) return SlmShimmer(intensity: 0.22 + 0.1 * breath, child: disc);
        if (cleared) return SlmShimmer(intensity: 0.08, child: disc);
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
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -1.2, 2.1, false, paint);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 2.0, 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant _EmeraldRingPainter oldDelegate) => oldDelegate.progress != progress;
}

class _StationPlaque extends StatelessWidget {
  final _Station station;
  final String asset;
  final Animation<double> glow;
  final bool fresh;
  final bool rested;
  final _GiftFace giftFace;
  final bool motion;
  final VoidCallback? onTap;

  const _StationPlaque({
    required this.station,
    required this.asset,
    required this.glow,
    required this.fresh,
    required this.rested,
    required this.giftFace,
    required this.motion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chest = station == _Station.gift;
    final active = giftFace == _GiftFace.active;
    final missed = giftFace == _GiftFace.missed;
    final lively = motion && (active || (giftFace == _GiftFace.none && fresh));
    final picture = Image.asset(
      asset,
      width: 96,
      height: 84,
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
                  0.45, 0.28, 0.12, 0, 10,
                  0.18, 0.42, 0.12, 0, 10,
                  0.12, 0.2, 0.38, 0, 8,
                  0, 0, 0, 1, 0,
                ]),
                child: picture,
              )
            : picture;

    Widget frame(double turn, Widget art) {
      final bob = lively
          ? switch (station) {
              _Station.gift => -5 * turn,
              _Station.identify => -2.2 * turn,
              _Station.lesson => -1.6 * turn,
              _ => -1.2 * turn,
            }
          : 0.0;
      final tilt = motion && fresh && station == _Station.life ? (turn - 0.5) * 0.1 : 0.0;
      return Opacity(
        opacity: missed ? 0.78 : dull ? 0.62 : 1,
        child: Transform.translate(
          offset: Offset(0, bob),
          child: Transform.rotate(
            angle: tilt,
            child: SizedBox(
              width: 96,
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (active)
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x66FFE7A3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xCCFFD56A).withValues(alpha: 0.55 + 0.35 * turn),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                  art,
                  if (station == _Station.hourly && fresh)
                    Align(
                      alignment: const Alignment(0, -0.16),
                      child: CustomPaint(size: const Size(22, 22), painter: _ClockPainter(turn)),
                    ),
                  if (chest && motion && active)
                    CustomPaint(size: const Size(96, 84), painter: _SparkPainter(turn)),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
      builder: (context, press, child) => Transform.scale(scale: 1 - 0.05 * press, child: child),
      child: body,
    );
  }
}

class _FinishMark extends StatelessWidget {
  final Animation<double> glow;
  final bool motion;
  final VoidCallback? onTap;

  const _FinishMark({required this.glow, required this.motion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final shield = AnimatedSafetyShield(size: 78, animate: motion, entrance: false);
    Widget glowAt(double pulse, Widget shield) => Transform.scale(
          scale: motion ? 1 + 0.06 * pulse : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(const Color(0xFFE8C56B), const Color(0xFF3DDC97), pulse)!.withValues(alpha: 0.72),
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
      builder: (context, press, child) => Transform.scale(scale: 1 - 0.05 * press, child: child),
      child: mark,
    );
  }
}

class _ObjectReveal extends StatefulWidget {
  final String asset;
  final double endScale;
  final VoidCallback onDone;

  const _ObjectReveal({required this.asset, required this.endScale, required this.onDone});

  @override
  State<_ObjectReveal> createState() => _ObjectRevealState();
}

class _ObjectRevealState extends State<_ObjectReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 780),
  );

  @override
  void initState() {
    super.initState();
    // Zoom in, hold a beat at peak, then hand off to kinetic text.
    _move.forward().whenComplete(() async {
      await Future<void>.delayed(const Duration(milliseconds: 220));
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
                offset: Offset(0, (1 - t.clamp(0.0, 1.0)) * 140),
                child: Transform.scale(
                  scale: scale,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD56A).withValues(alpha: 0.18 + 0.45 * t.clamp(0.0, 1.0)),
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

class _KineticReplyState extends State<_KineticReply> with SingleTickerProviderStateMixin {
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
    final titleWords = widget.title.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final bodyWords = widget.body.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
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
                      style: zlText(28, weight: FontWeight.w900, color: SlmColors.gold100, height: 1.15),
                    ),
                    const SizedBox(height: 14),
                    _KineticLine(
                      words: bodyWords,
                      clock: _play,
                      start: titleWords.length,
                      step: step,
                      style: zlText(16, weight: FontWeight.w600, color: SlmColors.ivory, height: 1.45),
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
    final t = Interval(begin, (begin + 0.28).clamp(begin + 0.01, 1.0), curve: Curves.easeOutCubic).transform(clock.value);
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
    final paint = Paint()..color = Color.fromRGBO(255, 236, 180, 0.25 + 0.55 * turn);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.18), 1.4, paint);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.28), 1.1, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) => oldDelegate.turn != turn;
}

class _ClockPainter extends CustomPainter {
  final double turn;

  const _ClockPainter(this.turn);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawLine(
      c,
      c + Offset(math.cos(turn * math.pi * 2 - 1.2) * 7, math.sin(turn * math.pi * 2 - 1.2) * 7),
      Paint()
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF1A2744),
    );
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) => oldDelegate.turn != turn;
}

