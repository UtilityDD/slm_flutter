import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/bangla_read_aloud.dart';
import '../home/level_lessons_sheet.dart' show playLessonCue;
import 'zero_loss_crew.dart';
import 'zero_loss_engine.dart';
import 'zero_loss_fx.dart';
import 'zero_loss_field.dart';
import 'zero_loss_models.dart';
import 'zero_loss_reveal.dart';
import 'zero_loss_rules.dart';
import 'zero_loss_stress.dart';
import 'zero_loss_opening.dart';
import 'zero_loss_tbt.dart';
import 'zero_loss_ui.dart';
import 'zero_loss_work_site.dart';

/// জিরো লস: one storm-night shift as the feeder in-charge.
class ZeroLossPage extends ConsumerStatefulWidget {
  const ZeroLossPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const ZeroLossPage()),
      );

  @override
  ConsumerState<ZeroLossPage> createState() => _ZeroLossPageState();
}

class _ZeroLossPageState extends ConsumerState<ZeroLossPage> {
  bool _muted = false;
  bool _starting = true;
  bool _rules = true;
  String? _lastCue;
  List<ScoreEntry>? _beat;
  Timer? _beatTimer;

  ZlVoice get _voice => ref.read(zlVoiceProvider);

  @override
  void initState() {
    super.initState();
    ZlMusic.start();
    _start();
  }

  @override
  void dispose() {
    _beatTimer?.cancel();
    ZlMusic.stop();
    super.dispose();
  }

  void _showBeat(List<ScoreEntry> entries) {
    _beatTimer?.cancel();
    setState(() => _beat = entries);
    _beatTimer = Timer(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _beat = null);
    });
  }

  Future<void> _start() async {
    _voice.stop();
    setState(() {
      _starting = true;
      _lastCue = null;
    });
    final setup = await createZeroLossSetup(randomize: true);
    if (!mounted) return;
    ref.read(zeroLossProvider.notifier).begin(setup);
    setState(() => _starting = false);
    if (!_rules) _cue(ref.read(zeroLossProvider)!);
  }

  void _closeRules() {
    setState(() {
      _rules = false;
      _lastCue = null;
    });
    final s = ref.read(zeroLossProvider);
    if (s != null) _cue(s);
  }

  (String, String)? _cueFor(ZeroLossState s, {bool arrived = false}) {
    String line(String key, {String crew = ''}) {
      final t = s.scenario.voice[key] ?? '';
      return s.activeFaultId == null ? s.setting.fill(t, crew: crew) : s.fillFor(s.activeFaultId!, t, crew: crew);
    }

    final faultId = s.activeFaultId;
    switch (s.phase) {
      case ZeroLossPhase.briefing:
      case ZeroLossPhase.tbtPreview:
        return null;
      case ZeroLossPhase.map:
        return null;
      case ZeroLossPhase.armour:
        return ('armour-$faultId', line('armour_bn'));
      case ZeroLossPhase.loading:
        final m = s.mission(faultId!);
        if (s.pendingCheck != null) return ('check-$faultId-${m.minutesUsed}', line('missing_gear_bn'));
        return ('load-$faultId-${m.minutesUsed}', line('loading_bn'));
      case ZeroLossPhase.chant:
        return null;
      case ZeroLossPhase.site:
        final m = s.mission(faultId!);
        final event = s.fault(faultId).events[m.eventIndex];
        final fb = s.pendingFeedback;
        if (fb != null) return s.duty ? null : ('fb-$faultId-${m.eventIndex}', fb.feedbackBn);
        if (!arrived && m.decisions.isEmpty) return null;
        final spoken = event.lineBn.isNotEmpty ? event.lineBn : event.situationBn;
        return ('ev-$faultId-${m.eventIndex}', s.fillFor(faultId, spoken));
      case ZeroLossPhase.outcome:
        final m = s.mission(faultId!);
        final text = switch (m.outcome) {
          MissionOutcome.accident => [
              m.injuredCrewId == null ? line('accident_public_bn') : line('accident_bn', crew: s.lineman(m.injuredCrewId!).name),
              if (m.accident != null) ...[
                s.scenario.accidentCause(m.accident!.cause).titleBn,
                s.scenario.accidentCause(m.accident!.cause).lineBn,
              ],
            ].join(' '),
          MissionOutcome.lucky => line('lucky_bn'),
          _ => s.isLate(faultId) ? line('late_bn') : line('safe_restore_bn'),
        };
        return ('out-$faultId', text);
      case ZeroLossPhase.debrief:
        return s.zeroLoss ? ('debrief', line('zero_loss_bn')) : null;
    }
  }

  void _cue(ZeroLossState s, {bool force = false}) {
    final c = _cueFor(s, arrived: force);
    if (c == null) {
      _voice.stop();
      _lastCue = null;
      return;
    }
    if (!force && c.$1 == _lastCue) return;
    _lastCue = c.$1;
    _voice.stop();
    _voice.say(c.$2);
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _voice.muted = _muted;
    if (_muted) _voice.stop();
  }

  Future<void> _confirmExit() async {
    final s = ref.read(zeroLossProvider);
    final midGame = s != null &&
        s.phase != ZeroLossPhase.briefing &&
        s.phase != ZeroLossPhase.tbtPreview &&
        s.phase != ZeroLossPhase.debrief;
    if (midGame) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ZlColors.panel,
          icon: const Icon(Icons.logout_rounded, color: ZlColors.amber),
          title: Text('শিফট ছেড়ে যাবেন?', style: zlText(17, weight: FontWeight.w800)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('থাকি')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('বের হই')),
          ],
        ),
      );
      if (leave != true) return;
    }
    _voice.stop();
    ZlMusic.stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(zeroLossProvider, (prev, next) {
      if (next == null || _starting || _rules) return;
      if (prev?.phase != next.phase) {
        _voice.stop();
        _lastCue = null;
      }
      if (prev?.phase != ZeroLossPhase.outcome && next.phase == ZeroLossPhase.outcome) {
        final accident = next.mission(next.activeFaultId!).outcome == MissionOutcome.accident;
        ZlFx.stopClock();
        if (accident) {
          ZlFx.cue('sounds/accident.wav', volume: 0.85);
          HapticFeedback.heavyImpact();
        } else {
          playLessonCue(true);
          HapticFeedback.mediumImpact();
        }
      }
      if (prev?.pendingCheck == null && next.pendingCheck != null) HapticFeedback.heavyImpact();
      if (prev != null && next.ledger.length > prev.ledger.length && prev.phase != next.phase) {
        final fresh = next.ledger.sublist(prev.ledger.length).where((e) => !next.duty || e.cause.liveInDuty).toList();
        final accident = next.phase == ZeroLossPhase.outcome &&
            next.activeFaultId != null &&
            next.mission(next.activeFaultId!).outcome == MissionOutcome.accident;
        if (fresh.isNotEmpty) {
          if (!accident) playLessonCue(!fresh.any((e) => e.points < 0));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showBeat(fresh);
          });
        }
      }
      _cue(next);
    });

    final s = ref.watch(zeroLossProvider);
    // Loading/site own their chrome — no green/red meters or step strip there.
    // Sparse chrome on cinematic / pick / field screens — meters belong on mid-duty steps only.
    final showStatus = !_rules &&
        s != null &&
        s.phase != ZeroLossPhase.briefing &&
        s.phase != ZeroLossPhase.tbtPreview &&
        s.phase != ZeroLossPhase.map &&
        s.phase != ZeroLossPhase.loading &&
        s.phase != ZeroLossPhase.site &&
        s.phase != ZeroLossPhase.debrief;
    final showSteps = !_rules &&
        s != null &&
        s.phase != ZeroLossPhase.briefing &&
        s.phase != ZeroLossPhase.tbtPreview &&
        s.phase != ZeroLossPhase.map &&
        s.phase != ZeroLossPhase.loading &&
        s.phase != ZeroLossPhase.site &&
        s.phase != ZeroLossPhase.debrief;
    final canHelp = !_rules && s != null && (s.phase == ZeroLossPhase.briefing || s.phase == ZeroLossPhase.map);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: ZlColors.amber, surface: ZlColors.panel),
        ),
        child: Scaffold(
          backgroundColor: ZlColors.bg,
          body: SafeArea(
            child: _starting || s == null
                ? const Center(child: CircularProgressIndicator(color: ZlColors.amber))
                : Column(
                    children: [
                      _TopBar(
                        state: s,
                        showSteps: showSteps,
                        muted: _muted,
                        musicMuted: ZlMusic.muted,
                        onMute: _toggleMute,
                        onMusic: () async {
                          await ZlMusic.setMuted(!ZlMusic.muted);
                          if (mounted) setState(() {});
                        },
                        onClose: _confirmExit,
                        onHelp: canHelp
                            ? () {
                                _voice.stop();
                                setState(() => _rules = true);
                              }
                            : null,
                      ),
                      if (showStatus) ZlStatusBar(state: s),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _phaseSwitcher(s),
                            CustomerPopLayer(active: !_rules && _customerPhases.contains(s.phase)),
                            if (!_rules && s.phase != ZeroLossPhase.site && s.phase != ZeroLossPhase.loading)
                              const ScoreToastLayer(),
                            if (_beat != null)
                              Positioned.fill(
                                child: _ScoreBeat(entries: _beat!),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // Keep public pressure on map/loading only — site stays clean.
  static const _customerPhases = {ZeroLossPhase.map, ZeroLossPhase.loading};

  Widget _phaseSwitcher(ZeroLossState s) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (c, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a),
            child: c,
          ),
        ),
        child: _rules
            ? ZeroLossRulesView(
                key: const ValueKey('rules'),
                scenario: s.scenario,
                onDone: _closeRules,
              )
            : KeyedSubtree(
                key: ValueKey('${s.phase}-${s.activeFaultId}'),
                child: _body(s),
              ),
      );

  Widget _body(ZeroLossState s) => switch (s.phase) {
        ZeroLossPhase.briefing => ZeroLossOpening(state: s),
        ZeroLossPhase.tbtPreview => ZeroLossOpening(state: s),
        ZeroLossPhase.map => _MapView(state: s),
        ZeroLossPhase.armour => const ZeroLossArmourView(),
        ZeroLossPhase.loading => const ZeroLossLoadingView(),
        ZeroLossPhase.chant => const ZeroLossTbtView(),
        ZeroLossPhase.site => const ZeroLossWorkSite(),
        ZeroLossPhase.outcome => _OutcomeView(state: s),
        ZeroLossPhase.debrief => _DebriefView(state: s, onReplay: _start, onExit: _confirmExit),
      };
}

/// The points for the step just finished, held on screen before the next page is usable.
class _ScoreBeat extends StatelessWidget {
  final List<ScoreEntry> entries;

  const _ScoreBeat({required this.entries});

  @override
  Widget build(BuildContext context) {
    final grouped = <ScoreCause, int>{};
    for (final e in entries) {
      grouped[e.cause] = (grouped[e.cause] ?? 0) + e.points;
    }
    final rows = grouped.entries.toList();
    return AbsorbPointer(
      child: SizedBox.expand(
        child: ColoredBox(
        color: const Color(0xD60B1220),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows.length; i++)
                PopIn(
                  delay: Duration(milliseconds: 90 * i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
                    child: Text(
                      '${signedBn(rows[i].value)}  ${rows[i].key.labelBn}',
                      textAlign: TextAlign.center,
                      style: zlText(32, weight: FontWeight.w900, color: scoreKindColor(rows[i].key.kind), height: 1.1),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final ZeroLossState state;
  final bool showSteps;
  final bool muted;
  final bool musicMuted;
  final VoidCallback onMute;
  final VoidCallback onMusic;
  final VoidCallback onClose;
  final VoidCallback? onHelp;

  const _TopBar({
    required this.state,
    required this.showSteps,
    required this.muted,
    required this.musicMuted,
    required this.onMute,
    required this.onMusic,
    required this.onClose,
    this.onHelp,
  });

  static const _steps = [
    (ZeroLossPhase.map, Icons.groups_rounded),
    (ZeroLossPhase.loading, Icons.local_shipping_rounded),
    (ZeroLossPhase.site, Icons.engineering_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final phase = state.phase;
    final idx = showSteps ? _steps.indexWhere((e) => e.$1 == phase) : -1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
      child: Row(
        children: [
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, color: ZlColors.soft)),
          Expanded(
            child: idx < 0
                ? Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: ZlColors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text('জিরো লস', style: zlText(15, weight: FontWeight.w900)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          state.setting.districtBn,
                          overflow: TextOverflow.ellipsis,
                          style: zlText(12, color: ZlColors.soft),
                        ),
                      ),
                    ],
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _steps.length; i++) ...[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == idx
                                  ? ZlColors.amber
                                  : (i < idx ? ZlColors.green.withValues(alpha: 0.25) : ZlColors.panel),
                            ),
                            child: Icon(
                              i < idx ? Icons.check_rounded : _steps[i].$2,
                              size: 16,
                              color: i == idx ? ZlColors.bg : (i < idx ? ZlColors.green : ZlColors.soft),
                            ),
                          ),
                          if (i < _steps.length - 1)
                            Container(width: 12, height: 2, color: i < idx ? ZlColors.green : ZlColors.line),
                        ],
                      ],
                    ),
                  ),
          ),
          if (onHelp != null)
            IconButton(onPressed: onHelp, icon: const Icon(Icons.help_outline_rounded, color: ZlColors.soft)),
          IconButton(
            onPressed: onMusic,
            tooltip: musicMuted ? 'সুর চালু' : 'সুর বন্ধ',
            icon: Icon(musicMuted ? Icons.music_off_rounded : Icons.music_note_rounded, color: ZlColors.soft),
          ),
          IconButton(
            onPressed: onMute,
            tooltip: muted ? 'কথা চালু' : 'কথা বন্ধ',
            icon: Icon(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: ZlColors.soft),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Briefing
// ---------------------------------------------------------------------------

class _BriefingView extends ConsumerStatefulWidget {
  final ZeroLossState state;

  const _BriefingView({required this.state});

  @override
  ConsumerState<_BriefingView> createState() => _BriefingViewState();
}

class _BriefingViewState extends ConsumerState<_BriefingView> {
  static const _rate = 0.46;
  late final ZlVoice _voice;
  /// 0 = control call, 1 = mode pick.
  int _beat = 0;
  int _clause = 0;

  ZeroLossState get s => widget.state;

  String get _callLine {
    final set = s.setting;
    final weather = set.region.weatherShortBn.replaceAll(' · ', ', ');
    return 'ও শুনুন। কন্ট্রোল থেকে বলছি। ${set.districtBn}-এ এখন $weather। ${set.office}-এর ফিডার ট্রিপ। ফল্ট দু জায়গায়। তাড়াহুড়ো নয় — সেফ হোম মেনে কাজ করুন।';
  }

  @override
  void initState() {
    super.initState();
    _voice = ref.read(zlVoiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  @override
  void dispose() {
    _voice.stop();
    super.dispose();
  }

  void _speak() {
    if (!mounted) return;
    if (_beat == 0) {
      _voice.say(_callLine, rate: _rate, onClause: (i) {
        if (mounted && _beat == 0 && _clause != i) setState(() => _clause = i);
      });
      return;
    }
    _voice.say('অনুশীলন, নাকি ডিউটি।', rate: _rate);
  }

  void _next() {
    if (_beat >= 1) return;
    _voice.stop();
    HapticFeedback.selectionClick();
    setState(() {
      _beat = 1;
      _clause = 0;
    });
    _speak();
  }

  @override
  Widget build(BuildContext context) {
    final choosing = _beat >= 1;
    final record = ref.watch(zeroLossRecordProvider).value;
    return Column(
      children: [
        Expanded(
          child: choosing
              ? _ModePick(
                  record: record,
                  onPractice: () {
                    _voice.stop();
                    ref.read(zeroLossProvider.notifier).startShift();
                  },
                  onDuty: () {
                    _voice.stop();
                    ref.read(zeroLossProvider.notifier).startShift(mode: ZeroLossMode.duty);
                  },
                )
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _next,
                  child: _OperatorBeat(key: const ValueKey('room'), speech: _callLine, clause: _clause),
                ),
        ),
        if (!choosing)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                TextButton(
                  onPressed: _next,
                  child: Text('এড়িয়ে যান', style: zlText(13, weight: FontWeight.w700, color: ZlColors.soft)),
                ),
                ZlButton(label: 'পরের', icon: Icons.arrow_forward_rounded, onTap: _next),
              ],
            ),
          ),
      ],
    );
  }
}

String _jobPhoto(FaultDispatch f) => f.sceneImage;

class _ModePick extends StatelessWidget {
  final ZeroLossRecord? record;
  final VoidCallback onPractice;
  final VoidCallback onDuty;

  const _ModePick({
    required this.record,
    required this.onPractice,
    required this.onDuty,
  });

  @override
  Widget build(BuildContext context) {
    final locked = record == null || record!.plays == 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('শিফট বেছে নিন', textAlign: TextAlign.center, style: zlText(24, weight: FontWeight.w900)),
          const SizedBox(height: 16),
          _ModeCard(
            icon: Icons.school_rounded,
            title: 'অনুশীলন',
            sub: 'টিবিটি দেখে কাজে নামুন',
            color: ZlColors.blue,
            onTap: onPractice,
          ),
          const SizedBox(height: 10),
          _ModeCard(
            icon: Icons.engineering_rounded,
            title: 'ডিউটি',
            sub: 'ফিল্ড চাপ · পয়েন্ট ×1.5',
            color: ZlColors.amber,
            locked: locked,
            onTap: onDuty,
          ),
        ],
      ),
    );
  }
}

class _OperatorBeat extends StatelessWidget {
  final String speech;
  final int clause;

  const _OperatorBeat({super.key, required this.speech, required this.clause});

  @override
  Widget build(BuildContext context) {
    final bits = speechBits(speech);
    final line = bits.isEmpty ? speech : bits[clause.clamp(0, bits.length - 1)].shown;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/zero_loss/scene/bg_control_room.webp', fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x22000000), Color(0x00000000), Color(0xF20B1220)],
                  stops: [0, 0.35, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                children: [
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: ZlColors.amber, width: 2.4),
                          image: const DecorationImage(
                            image: AssetImage('assets/zero_loss/scene/operator_control.jpg'),
                            fit: BoxFit.cover,
                            alignment: Alignment(0, -0.2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                          decoration: BoxDecoration(
                            color: const Color(0xF0141C2C),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                            border: Border.all(color: ZlColors.amber.withValues(alpha: 0.7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('কন্ট্রোল', style: zlText(13, weight: FontWeight.w800, color: ZlColors.amber)),
                              const SizedBox(height: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: Text(
                                  line,
                                  key: ValueKey(line),
                                  style: zlText(20, weight: FontWeight.w800, height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

/// Big picture button for choosing practice or duty.
class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final Color color;
  final bool locked;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.color,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = locked ? ZlColors.soft : color;
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Material(
        color: c.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c, width: 1.6)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: locked
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('আগে একটা অনুশীলন শিফট শেষ করুন'), duration: Duration(seconds: 2)),
                  )
              : () {
                  HapticFeedback.mediumImpact();
                  onTap();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Icon(locked ? Icons.lock_rounded : icon, color: c, size: 34),
                const SizedBox(height: 4),
                Text(title, style: zlText(17, weight: FontWeight.w900, color: c)),
                Text(sub, style: zlText(11.5, weight: FontWeight.w700, color: ZlColors.soft)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map: choose a fault and pick the team
// ---------------------------------------------------------------------------

class _MapView extends ConsumerStatefulWidget {
  final ZeroLossState state;

  const _MapView({required this.state});

  @override
  ConsumerState<_MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<_MapView> {
  static const _rate = 0.40;
  // One-job games jump straight into crew pick.
  late final ZlVoice _voice;
  bool _crew = false;

  ZeroLossState get s => widget.state;

  @override
  void initState() {
    super.initState();
    _voice = ref.read(zlVoiceProvider);
    // One job → skip map juggling, open crew pick.
    if (s.scenario.faults.length == 1) _crew = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_crew) {
        _speakCrew();
      } else {
        _speakJob();
      }
    });
  }

  void _speakJob() {
    final id = s.selectedFaultId;
    if (id == null) return;
    final f = s.fault(id);
    _voice.say('${s.mission(id).location}। ${f.shortTitleBn}।', rate: _rate);
  }

  void _speakCrew() {
    final id = s.selectedFaultId;
    if (id == null) return;
    final f = s.fault(id);
    final where = f.work == FaultWork.climb ? 'পোলে উঠতে হবে' : 'মাটিতে কাজ';
    _voice.say('$where। ${n(f.requiredCrewCount)} জন বাছুন।', rate: _rate);
  }

  void _focus(String id) {
    ref.read(zeroLossProvider.notifier).selectFault(id);
    _speakJob();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.read(zeroLossProvider.notifier);
    final selected = s.selectedFaultId!;
    final f = s.fault(selected);
    final m = s.mission(selected);
    final need = f.requiredCrewCount - m.assignedCrew.length;
    final waiting = m.stage == MissionStage.waiting;
    final other = s.scenario.faults.where((fault) => fault.id != selected).toList();

    if (_crew && waiting) {
      final picked = m.assignedCrew.length;
      final total = f.requiredCrewCount;
      final workLabel = f.work == FaultWork.climb ? 'পোল কাজ' : 'মাটি কাজ';
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Column(
              children: [
                Text('টিম বাছুন', textAlign: TextAlign.center, style: zlText(22, weight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  '${m.location}  ·  $workLabel',
                  textAlign: TextAlign.center,
                  style: zlText(13, color: ZlColors.soft),
                ),
                const SizedBox(height: 14),
                TeamSeats(state: s, faultId: selected, size: 42),
                const SizedBox(height: 8),
                Text(
                  need > 0 ? '${n(picked)} / ${n(total)} জন নির্বাচিত' : 'টিম তৈরি — এগিয়ে যান',
                  style: zlText(13, weight: FontWeight.w700, color: need > 0 ? ZlColors.amber : ZlColors.green),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: _CrewStage(
                children: [
                  for (final man in s.crew)
                    CrewCard(
                      state: s,
                      man: man,
                      faultId: selected,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        final had = s.mission(selected).assignedCrew.contains(man.id);
                        game.assignLineman(man.id);
                        if (!had) _voice.say('${man.name}। ${man.noteBn}', rate: _rate);
                      },
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                if (s.scenario.faults.length > 1)
                  TextButton(
                    onPressed: () {
                      setState(() => _crew = false);
                      _speakJob();
                    },
                    child: Text('কাজ বদলান', style: zlText(13, weight: FontWeight.w700, color: ZlColors.soft)),
                  ),
                ZlButton(
                  label: need > 0 ? 'আরও ${n(need)} জন বাছুন' : 'সরঞ্জাম নিন',
                  icon: need > 0 ? Icons.person_add_alt_1_rounded : Icons.local_shipping_rounded,
                  onTap: game.canLoad(selected) ? () => game.openLoading(selected) : null,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: _MapCanvas(state: s, onSelect: _focus),
          ),
        ),
        if (other.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Column(
              children: [
                for (final fault in other)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _WaitingJob(
                      state: s,
                      fault: fault,
                      onTap: () => _focus(fault.id),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ZlButton(
            label: waiting ? 'এই কাজ · টিম বাছুন' : 'এই কাজ শেষ',
            icon: waiting ? Icons.groups_rounded : Icons.check_rounded,
            onTap: waiting
                ? () {
                    setState(() => _crew = true);
                    _speakCrew();
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

/// The crew stand in the space they have. No sideways list, no empty page below.
class _CrewStage extends StatelessWidget {
  final List<Widget> children;

  const _CrewStage({required this.children});

  @override
  Widget build(BuildContext context) {
    final n = children.length;
    if (n <= 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [for (final child in children) Expanded(child: child)],
      );
    }
    final top = (n + 1) ~/ 2;
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [for (final child in children.take(top)) Expanded(child: child)],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Spacer(),
              for (final child in children.skip(top)) Expanded(flex: 2, child: child),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaitingJob extends StatelessWidget {
  final ZeroLossState state;
  final FaultDispatch fault;
  final VoidCallback onTap;

  const _WaitingJob({required this.state, required this.fault, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = state.mission(fault.id).stage != MissionStage.waiting;
    return Material(
      color: ZlColors.panel,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(done ? Icons.check_rounded : Icons.hourglass_bottom_rounded, color: done ? ZlColors.green : ZlColors.soft, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state.mission(fault.id).location,
                  overflow: TextOverflow.ellipsis,
                  style: zlText(16, weight: FontWeight.w800),
                ),
              ),
              Text(done ? 'শেষ' : 'অপেক্ষায়', style: zlText(13, weight: FontWeight.w700, color: ZlColors.soft)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapCanvas extends StatefulWidget {
  final ZeroLossState state;
  final ValueChanged<String> onSelect;

  const _MapCanvas({required this.state, required this.onSelect});

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  static const _spots = {'A': Offset(0.28, 0.30), 'B': Offset(0.72, 0.46)};
  static const _depot = Offset(0.5, 0.64);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final focus = s.fault(s.selectedFaultId!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: LayoutBuilder(
        builder: (_, box) {
          Offset at(Offset p) => Offset(p.dx * box.maxWidth, p.dy * box.maxHeight);
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(_jobPhoto(focus), fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x66101828), Color(0x22101828), Color(0xE6101828)],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapPainter(
                    depot: at(_depot),
                    spots: [for (final f in s.scenario.faults) at(_spots[f.slot] ?? const Offset(0.5, 0.4))],
                  ),
                ),
              ),
              const Positioned.fill(child: StormOverlay(drops: 36)),
              Positioned(
                left: at(_depot).dx - 18,
                top: at(_depot).dy - 14,
                child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 28),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: ZlTag(label: s.setting.region.weatherShortBn, color: ZlColors.blue, icon: Icons.thunderstorm_rounded),
              ),
              for (final f in s.scenario.faults) _pin(s, f, at(_spots[f.slot] ?? const Offset(0.5, 0.4))),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.mission(focus.id).location, style: zlText(15, weight: FontWeight.w800, color: ZlColors.amber)),
                    const SizedBox(height: 2),
                    Text(focus.shortTitleBn, style: zlText(26, weight: FontWeight.w900, height: 1.1)),
                    const SizedBox(height: 4),
                    Text('${n(focus.urgencyMinutes)} মিনিট', style: zlText(16, weight: FontWeight.w800, color: ZlColors.blue)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pin(ZeroLossState s, FaultDispatch f, Offset p) {
    final m = s.mission(f.id);
    final done = m.stage == MissionStage.done;
    final color = done ? outcomeColor(m.outcome) : severityColor(f.severity);
    final selected = s.selectedFaultId == f.id;
    return Positioned(
      left: p.dx - 60,
      top: p.dy - 24,
      width: 120,
      child: GestureDetector(
        onTap: () => widget.onSelect(f.id),
        child: Column(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => CustomPaint(
                  painter: _PinPainter(color: color, t: done ? 0 : _pulse.value, selected: selected),
                  child: Center(
                    child: Icon(
                      done
                          ? (m.outcome == MissionOutcome.accident ? Icons.personal_injury_rounded : Icons.lightbulb_rounded)
                          : (f.work == FaultWork.climb ? Icons.electric_bolt_rounded : Icons.cable_rounded),
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ZlColors.bg.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
                border: selected ? Border.all(color: color) : null,
              ),
              child: Text(m.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: zlText(10.5, weight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final Offset depot;
  final List<Offset> spots;

  _MapPainter({required this.depot, required this.spots});

  @override
  void paint(Canvas canvas, Size size) {
    final river = Path()
      ..moveTo(0, size.height * 0.58)
      ..cubicTo(size.width * 0.3, size.height * 0.46, size.width * 0.55, size.height * 0.72, size.width, size.height * 0.6);
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xAAE0F2FE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    final feeder = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (final p in spots) {
      final path = Path()
        ..moveTo(depot.dx, depot.dy)
        ..quadraticBezierTo((depot.dx + p.dx) / 2, min(depot.dy, p.dy) + 20, p.dx, p.dy);
      for (final metric in path.computeMetrics()) {
        var d = 0.0;
        while (d < metric.length) {
          canvas.drawPath(metric.extractPath(d, min(d + 7, metric.length)), feeder);
          d += 12;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.depot != depot || old.spots != spots;
}

class _PinPainter extends CustomPainter {
  final Color color;
  final double t;
  final bool selected;

  _PinPainter({required this.color, required this.t, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (t > 0) canvas.drawCircle(c, 11 + 13 * t, Paint()..color = color.withValues(alpha: 0.45 * (1 - t)));
    if (selected) {
      canvas.drawCircle(
        c,
        17,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.drawCircle(c, 14, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.t != t || old.color != color || old.selected != selected;
}

// ---------------------------------------------------------------------------
// Outcome of one mission
// ---------------------------------------------------------------------------

class _OutcomeView extends ConsumerStatefulWidget {
  final ZeroLossState state;

  const _OutcomeView({required this.state});

  @override
  ConsumerState<_OutcomeView> createState() => _OutcomeViewState();
}

class _OutcomeViewState extends ConsumerState<_OutcomeView> {
  bool _score = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final faultId = s.activeFaultId!;
    final nextLabel = s.allDone ? 'শিফট রিপোর্ট' : 'পরের ফল্ট';
    void goOn() => ref.read(zeroLossProvider.notifier).closeOutcome();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _score
          ? _OutcomeScore(
              key: const ValueKey('score'),
              state: s,
              faultId: faultId,
              nextLabel: nextLabel,
              onBack: () => setState(() => _score = false),
              onNext: goOn,
            )
          : _OutcomeMoment(
              key: const ValueKey('moment'),
              state: s,
              faultId: faultId,
              nextLabel: nextLabel,
              onScore: () {
                HapticFeedback.selectionClick();
                setState(() => _score = true);
              },
              onNext: goOn,
            ),
    );
  }
}

class _BeatLine {
  final String text;
  final double size;
  final Color color;

  const _BeatLine(this.text, this.size, this.color);
}

/// Full-screen celebration or accident. The score stays on the next step.
class _OutcomeMoment extends StatefulWidget {
  final ZeroLossState state;
  final String faultId;
  final String nextLabel;
  final VoidCallback onScore;
  final VoidCallback onNext;

  const _OutcomeMoment({
    super.key,
    required this.state,
    required this.faultId,
    required this.nextLabel,
    required this.onScore,
    required this.onNext,
  });

  @override
  State<_OutcomeMoment> createState() => _OutcomeMomentState();
}

class _OutcomeMomentState extends State<_OutcomeMoment> with SingleTickerProviderStateMixin {
  late final _flash = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final m = s.mission(widget.faultId);
    final accident = m.outcome == MissionOutcome.accident;
    final late = s.isLate(widget.faultId);
    final color = outcomeColor(m.outcome);
    final cause = m.accident == null ? null : s.scenario.accidentCause(m.accident!.cause);
    final victim = m.injuredCrewId == null ? null : s.lineman(m.injuredCrewId!);
    final lines = accident
        ? [
            const _BeatLine('দুর্ঘটনা', 52, Color(0xFFFCA5A5)),
            if (cause != null) _BeatLine(cause.titleBn, 28, Colors.white),
            if (cause != null) _BeatLine(cause.lineBn, 16, ZlColors.soft),
            _BeatLine(victim?.name ?? 'গ্রামের লোক', 20, Colors.white),
          ]
        : [
            _BeatLine('লাইন চালু!', 52, color),
            _BeatLine(m.location, 20, ZlColors.amber),
            if (m.outcome == MissionOutcome.lucky)
              const _BeatLine('ভাগ্যে বাঁচা', 30, ZlColors.amber)
            else if (late)
              const _BeatLine('দেরিতে', 30, ZlColors.red)
            else
              const _BeatLine('সবাই ফিরল', 30, ZlColors.green),
          ];

    return Stack(
      fit: StackFit.expand,
      children: [
        if (accident && cause != null)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.14, end: 1),
            duration: const Duration(milliseconds: 1800),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Image.asset(cause.image, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: ZlColors.panelHi)),
          )
        else
          _VillageScene(lit: !accident, color: color),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: accident
                  ? const [Color(0x667F1D1D), Color(0x22101828), Color(0xF20B1220)]
                  : const [Color(0x220B1220), Color(0x66101828), Color(0xF20B1220)],
              stops: const [0, 0.42, 1],
            ),
          ),
        ),
        if (accident) const Positioned.fill(child: StormOverlay(drops: 28, lightning: true)),
        AnimatedBuilder(
          animation: _flash,
          builder: (_, _) {
            final t = _flash.value;
            if (accident) {
              return IgnorePointer(
                child: ColoredBox(color: ZlColors.red.withValues(alpha: (1 - t) * 0.72)),
              );
            }
            final ring = Curves.easeOut.transform(t);
            return IgnorePointer(
              child: Center(
                child: Container(
                  width: 80 + 520 * ring,
                  height: 80 + 520 * ring,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ZlColors.amber.withValues(alpha: (1 - t) * 0.7), width: 3),
                  ),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 150),
          child: Center(child: _KineticLines(lines: lines)),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ZlButton(
                label: 'পয়েন্ট দেখুন',
                icon: Icons.receipt_long_rounded,
                outlined: true,
                color: Colors.white,
                onTap: widget.onScore,
              ),
              const SizedBox(height: 8),
              ZlButton(label: widget.nextLabel, icon: Icons.arrow_forward_rounded, onTap: widget.onNext),
            ],
          ),
        ),
      ],
    );
  }
}

class _KineticLines extends StatefulWidget {
  final List<_BeatLine> lines;

  const _KineticLines({required this.lines});

  @override
  State<_KineticLines> createState() => _KineticLinesState();
}

class _KineticLinesState extends State<_KineticLines> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 520 + widget.lines.length * 620),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.lines.length;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < n; i++)
            _line(widget.lines[i], i, n),
        ],
      ),
    );
  }

  Widget _line(_BeatLine line, int i, int n) {
    final start = (i / (n + 0.35)).clamp(0.0, 0.82);
    final t = ((_c.value - start) / 0.28).clamp(0.0, 1.0);
    final eased = Curves.easeOutBack.transform(t);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - eased) * 22),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line.text,
            textAlign: TextAlign.center,
            style: zlText(line.size, weight: FontWeight.w900, color: line.color, height: 1.15),
          ),
        ),
      ),
    );
  }
}

/// Score, time and the steps, after the moment.
class _OutcomeScore extends StatelessWidget {
  final ZeroLossState state;
  final String faultId;
  final String nextLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _OutcomeScore({
    super.key,
    required this.state,
    required this.faultId,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final s = state;
    final f = s.fault(faultId);
    final m = s.mission(faultId);
    final accident = m.outcome == MissionOutcome.accident;
    final late = s.isLate(faultId);
    final best = m.decisions.where((d) => d.option.best).length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              Text('পয়েন্ট', textAlign: TextAlign.center, style: zlText(28, weight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(m.location, textAlign: TextAlign.center, style: zlText(15, weight: FontWeight.w700, color: ZlColors.amber)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < m.assignedCrew.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: CrewFace(
                        man: s.lineman(m.assignedCrew[i]),
                        size: 48,
                        ring: m.assignedCrew[i] == m.injuredCrewId ? ZlColors.red : ZlColors.green,
                      ),
                    ),
                ],
              ),
              if (accident) ...[
                const SizedBox(height: 14),
                ZlPanel(
                  border: ZlColors.red,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const _AmbulanceIcon(),
                      const SizedBox(width: 12),
                      Expanded(child: Text(s.setting.hospital, style: zlText(14, weight: FontWeight.w800))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BigStat(
                    icon: Icons.timer_rounded,
                    value: '${n(s.finishMinute(faultId))}′',
                    sub: 'সীমা ${n(f.urgencyMinutes)}′',
                    color: late ? ZlColors.red : ZlColors.green,
                  ),
                  _BigStat(
                    icon: Icons.warning_rounded,
                    value: pct(m.finalRisk),
                    sub: 'ঝুঁকি',
                    color: m.finalRisk >= 0.15 ? ZlColors.red : m.finalRisk >= 0.07 ? ZlColors.orange : ZlColors.green,
                  ),
                  _BigStat(
                    icon: Icons.fact_check_rounded,
                    value: '${n(best)}/${n(m.decisions.length)}',
                    sub: 'সঠিক',
                    color: best == m.decisions.length ? ZlColors.green : ZlColors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ScoreBreakdown(
                entries: s.ledger.where((e) => e.faultId == faultId).toList(),
                totalLabel: '${m.location}-এর পয়েন্ট',
              ),
              const SizedBox(height: 14),
              MantraRail(scenario: s.scenario, report: s.mantraReport(faultId)),
              const SizedBox(height: 14),
              MissionReplay(state: s, faultId: faultId),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              ZlButton(
                label: 'মুহূর্ত',
                icon: Icons.slideshow_rounded,
                outlined: true,
                color: ZlColors.soft,
                onTap: onBack,
              ),
              const SizedBox(height: 8),
              ZlButton(label: nextLabel, icon: Icons.arrow_forward_rounded, onTap: onNext),
            ],
          ),
        ),
      ],
    );
  }
}

class _BigStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String sub;
  final Color color;

  const _BigStat({required this.icon, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        Text(value, style: zlText(18, weight: FontWeight.w900, color: color)),
        Text(sub, style: zlText(11, color: ZlColors.soft)),
      ],
    );
  }
}

class _AmbulanceIcon extends StatelessWidget {
  const _AmbulanceIcon();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -40, end: 0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (_, v, c) => Transform.translate(offset: Offset(v, 0), child: c),
      child: const CircleAvatar(
        radius: 22,
        backgroundColor: ZlColors.red,
        child: Icon(Icons.emergency_rounded, color: Colors.white),
      ),
    );
  }
}

/// A row of village houses whose windows light up one by one.
class _VillageScene extends StatefulWidget {
  final bool lit;
  final Color color;

  const _VillageScene({required this.lit, required this.color});

  @override
  State<_VillageScene> createState() => _VillageSceneState();
}

class _VillageSceneState extends State<_VillageScene> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(painter: _VillagePainter(t: widget.lit ? _c.value : 0, glow: widget.color)),
        ),
        StormOverlay(drops: widget.lit ? 20 : 60, lightning: !widget.lit),
      ],
    );
  }
}

class _VillagePainter extends CustomPainter {
  final double t;
  final Color glow;

  _VillagePainter({required this.t, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Color.lerp(const Color(0xFF0B1220), const Color(0xFF1E293B), t)!;
    canvas.drawRect(Offset.zero & size, Paint()..color = sky);
    final ground = size.height * 0.82;
    canvas.drawRect(Rect.fromLTWH(0, ground, size.width, size.height - ground), Paint()..color = const Color(0xFF14231A));

    final wire = Paint()
      ..color = Color.lerp(const Color(0xFF475569), ZlColors.amber, t)!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final poles = [0.06, 0.5, 0.94];
    for (final x in poles) {
      canvas.drawLine(Offset(size.width * x, ground), Offset(size.width * x, size.height * 0.2), Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 4);
    }
    for (var i = 0; i < poles.length - 1; i++) {
      final a = Offset(size.width * poles[i], size.height * 0.22);
      final b = Offset(size.width * poles[i + 1], size.height * 0.22);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo((a.dx + b.dx) / 2, a.dy + 18, b.dx, b.dy);
      if (t > 0) {
        canvas.drawPath(path, Paint()
          ..color = ZlColors.amber.withValues(alpha: 0.35 * t)
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      }
      canvas.drawPath(path, wire);
    }

    const houses = 6;
    final w = size.width / (houses + 1);
    for (var i = 0; i < houses; i++) {
      final x = w * 0.5 + i * w * 1.08;
      final h = size.height * (0.26 + (i % 3) * 0.05);
      final body = Rect.fromLTWH(x, ground - h, w * 0.85, h);
      canvas.drawRect(body, Paint()..color = const Color(0xFF334155));
      final roof = Path()
        ..moveTo(body.left - 4, body.top)
        ..lineTo(body.center.dx, body.top - h * 0.45)
        ..lineTo(body.right + 4, body.top)
        ..close();
      canvas.drawPath(roof, Paint()..color = const Color(0xFF7C2D12));
      final on = (t * houses - i).clamp(0.0, 1.0);
      final win = Color.lerp(const Color(0xFF1E293B), const Color(0xFFFDE68A), on)!;
      final ww = body.width * 0.28;
      for (final dx in [0.14, 0.58]) {
        final r = Rect.fromLTWH(body.left + body.width * dx, body.top + h * 0.25, ww, ww);
        if (on > 0) {
          canvas.drawRect(r.inflate(4), Paint()
            ..color = const Color(0xFFFDE68A).withValues(alpha: 0.3 * on)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        }
        canvas.drawRect(r, Paint()..color = win);
      }
    }
  }

  @override
  bool shouldRepaint(_VillagePainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Debrief: mantra scorecard and lessons
// ---------------------------------------------------------------------------

class _DebriefView extends ConsumerStatefulWidget {
  final ZeroLossState state;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  const _DebriefView({required this.state, required this.onReplay, required this.onExit});

  @override
  ConsumerState<_DebriefView> createState() => _DebriefViewState();
}

class _DebriefViewState extends ConsumerState<_DebriefView> {
  ZeroLossRecord? _record;
  bool _newBest = false;

  @override
  void initState() {
    super.initState();
    _save();
  }

  Future<void> _save() async {
    final (record, newBest) = await ZeroLossRecord.save(
      points: widget.state.points,
      zeroLoss: widget.state.zeroLoss,
      countsForBest: widget.state.duty,
    );
    ref.invalidate(zeroLossRecordProvider);
    if (!mounted) return;
    setState(() {
      _record = record;
      _newBest = newBest;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final sc = s.scenario;
    final zero = s.zeroLoss;
    final badge = zero ? ZlColors.amber : ZlColors.red;
    final report = s.mantraReport();
    final pts = s.points;
    final ptsColor = pts < 0 ? ZlColors.red : ZlColors.amber;

    final lessons = <Widget>[];
    for (final f in sc.faults) {
      final m = s.mission(f.id);
      for (final d in m.decisions.where((d) => !d.option.best)) {
        final mantra = sc.mantra(d.event.mantra);
        lessons.add(_Lesson(
          mantra: mantra,
          title: 'টিবিটি · ${mantra.nameBn}',
          body: s.fillFor(f.id, d.option.shortBn.isEmpty ? d.option.textBn : d.option.shortBn),
          image: d.event.image,
        ));
      }
      for (final (man, id) in s.missingBody(f.id)) {
        final g = sc.gearById(id);
        final mantra = sc.mantra(g.mantra);
        lessons.add(_Lesson(
          mantra: mantra,
          title: 'টিবিটি · ${mantra.nameBn}',
          body: '${s.lineman(man).name}: ${g.nameBn} ছাড়া',
          gear: g,
        ));
      }
      for (final id in {...m.missingSafety, ...m.wrongWorn}) {
        final g = sc.gearById(id);
        final mantra = sc.mantra(g.mantra);
        lessons.add(_Lesson(
          mantra: mantra,
          title: 'টিবিটি · ${mantra.nameBn}',
          body: g.kind == GearKind.decoy ? '${g.nameBn} বেছেছিলেন' : '${g.nameBn} ছাড়াই গেছেন',
          gear: g,
        ));
      }
      for (final g in m.packedGear.where((g) => g.kind == GearKind.decoy)) {
        final mantra = sc.mantra(g.mantra);
        lessons.add(_Lesson(
          mantra: mantra,
          title: 'টিবিটি · ${mantra.nameBn}',
          body: '${g.nameBn} ট্রাকে',
          gear: g,
        ));
      }
      if (m.outcome == MissionOutcome.accident && m.accident != null) {
        final cause = sc.accidentCause(m.accident!.cause);
        lessons.insert(
          0,
          _Lesson(
            mantra: sc.mantra('mend'),
            title: cause.titleBn,
            body: cause.lineBn,
            image: cause.image,
          ),
        );
      }
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              Center(
                child: PopIn(
                  child: Column(
                    children: [
                      Text(
                        pts > 0 ? '+${n(pts)}' : n(pts),
                        style: zlText(42, weight: FontWeight.w900, color: ptsColor, height: 1),
                      ),
                      const SizedBox(height: 6),
                      Text(zero ? 'জিরো লস' : 'ক্ষতি', style: zlText(18, weight: FontWeight.w900, color: badge)),
                      if (_newBest)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('নতুন সেরা!', style: zlText(13, weight: FontWeight.w800, color: ZlColors.amber)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ScoreBreakdown(entries: s.ledger),
              const SizedBox(height: 16),
              Text('টিবিটি চেক', style: zlText(16, weight: FontWeight.w900)),
              const SizedBox(height: 8),
              for (var i = 0; i < sc.mantras.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _TbtCheckRow(index: i + 1, mantra: sc.mantras[i], ok: report[sc.mantras[i].id]),
                ),
              const SizedBox(height: 12),
              for (final f in sc.faults)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ZlPanel(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        TeamSeats(state: s, faultId: f.id, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(s.mission(f.id).location, overflow: TextOverflow.ellipsis, style: zlText(13.5, weight: FontWeight.w800)),
                        ),
                        IconStat(
                          icon: Icons.timer_outlined,
                          text: '${n(s.finishMinute(f.id))}/${n(f.urgencyMinutes)}′',
                          color: s.isLate(f.id) ? ZlColors.red : ZlColors.soft,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          s.mission(f.id).outcome == MissionOutcome.accident ? Icons.local_hospital_rounded : Icons.lightbulb_rounded,
                          color: outcomeColor(s.mission(f.id).outcome),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              if (lessons.isNotEmpty) ...[
                Text('কী ভেঙেছে', style: zlText(16, weight: FontWeight.w900)),
                const SizedBox(height: 8),
                ...lessons,
              ] else
                ZlPanel(
                  border: ZlColors.green,
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: ZlColors.green, size: 30),
                      const SizedBox(width: 10),
                      Expanded(child: Text('টিবিটি মেনেছেন। সবাই ফিরেছে।', style: zlText(14, weight: FontWeight.w700))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(child: ZlButton(label: 'বের হন', outlined: true, color: ZlColors.soft, onTap: widget.onExit)),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: ZlButton(label: 'নতুন জেলা', icon: Icons.refresh_rounded, onTap: widget.onReplay)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TbtCheckRow extends StatelessWidget {
  final int index;
  final SafetyMantra mantra;
  final bool? ok;

  const _TbtCheckRow({required this.index, required this.mantra, required this.ok});

  @override
  Widget build(BuildContext context) {
    final c = ok == null ? ZlColors.soft : (ok! ? ZlColors.green : ZlColors.red);
    return ZlPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: c.withValues(alpha: 0.35),
      child: Row(
        children: [
          MantraBadge(mantra: mantra, size: 28, ok: ok, active: ok == false),
          const SizedBox(width: 10),
          Expanded(
            child: Text('${n(index)}. ${mantra.nameBn}', style: zlText(14, weight: FontWeight.w800)),
          ),
          Icon(
            ok == null ? Icons.remove_rounded : (ok! ? Icons.check_rounded : Icons.close_rounded),
            color: c,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _Lesson extends StatelessWidget {
  final SafetyMantra mantra;
  final String title;
  final String body;
  final String? image;
  final Gear? gear;

  const _Lesson({required this.mantra, required this.title, required this.body, this.image, this.gear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ZlPanel(
        border: ZlColors.red.withValues(alpha: 0.5),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (gear != null)
              GearPicture(gear: gear!, size: 54)
            else if (image != null && image!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(image!, width: 54, height: 54, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox(width: 54)),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MantraBadge(mantra: mantra, size: 20),
                      const SizedBox(width: 6),
                      Text(mantra.nameBn, style: zlText(12, weight: FontWeight.w800, color: mantraColor(mantra.id))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: zlText(13.5, weight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(body, style: zlText(12.5, color: ZlColors.soft, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
