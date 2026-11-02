import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_hold.dart';
import '../auth/verify_sheet.dart';
import '../auth/verify_tick.dart';
import '../shell/app_routes.dart';
import '../shell/shell_providers.dart';
import 'home_toolbox.dart';
import 'path_intro_page.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _score = 0;
  int _deaths = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBoard());
  }

  /// Same numbers the ladder already saves. Not a new score.
  Future<void> _loadBoard() async {
    final prefs = await SharedPreferences.getInstance();
    final score = prefs.getInt('ds_career_score') ?? 0;
    final ranks = prefs.getStringList('ds_best_ranks') ?? const <String>[];
    final danger = prefs.getStringList('ds_danger_counts') ?? const <String>[];
    var deaths = 0;
    final n = math.min(ranks.length, danger.length);
    for (var i = 0; i < n; i++) {
      if (ranks[i].isEmpty) continue;
      final d = int.tryParse(danger[i]);
      if (d != null && d > 0) deaths += d;
    }
    if (!mounted) return;
    setState(() {
      _score = score;
      _deaths = deaths;
    });
  }

  void _openIntro() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    HapticFeedback.lightImpact();
    Navigator.of(context)
        .push(
          SlmPageRoute<void>(
            builder: (_) => PathIntroPage(reduceMotion: reduce),
            style: SlmTransition.fadeRise,
          ),
        )
        .then((_) => _loadBoard());
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);
    final profile = auth.profile;
    final guest = auth.isGuest || !auth.isAuthenticated;
    final verified = linemanIsVerified(auth, ref.watch(verifyHoldProvider));
    final fullName = profile?.fullName?.trim() ?? '';
    final slmId = profile?.slmId?.trim() ?? '';
    final guestLabel = tr(bn, 'অতিথি', 'Guest');
    final name = guest
        ? guestLabel
        : (fullName.isNotEmpty ? fullName : (slmId.isNotEmpty ? slmId : guestLabel));
    final reduce = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Theme(
              data: SlmTheme.night(),
              child: const SlmBackground(constrain: false, child: SizedBox.expand()),
            ),
          ),
          Theme(
            data: SlmTheme.night(),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 20),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _CornerMarks(score: _score, deaths: _deaths),
                        const Spacer(),
                        HomeToolboxButton(onTap: () => openHomeToolbox(context)),
                      ],
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final shield = math.min(MediaQuery.sizeOf(context).shortestSide * 0.62, box.maxHeight * 0.48);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SlmReveal(
                                child: _Welcome(label: tr(bn, 'স্বাগতম', 'Welcome')),
                              ),
                              const SizedBox(height: 16),
                              SlmReveal(
                                delay: const Duration(milliseconds: 180),
                                child: _NameLine(
                                  name: name,
                                  verified: verified,
                                  onName: () {
                                    Navigator.of(context).pushNamed(guest ? AppRoutes.login : AppRoutes.more);
                                  },
                                  onTick: verified ? null : () => showVerifySheet(context),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _PathMark(
                                shield: shield,
                                reduceMotion: reduce,
                                subtitle: tr(bn, 'ঘরে আপনার জন্য কেউ অপেক্ষা করছে।', 'Someone at home is waiting for you.'),
                                onOpen: _openIntro,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  final String label;

  const _Welcome({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SlmText(
          label,
          role: SlmTextRole.label,
          color: SlmColors.gold200,
          weight: FontWeight.w600,
          align: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          width: 72,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x00D9B25F), SlmColors.gold400, Color(0x00D9B25F)],
            ),
          ),
        ),
      ],
    );
  }
}

class _NameLine extends StatelessWidget {
  final String name;
  final bool verified;
  final VoidCallback onName;
  final VoidCallback? onTick;

  const _NameLine({
    required this.name,
    required this.verified,
    required this.onName,
    required this.onTick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: GestureDetector(
            onTap: onName,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: banglaFont,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.25,
                letterSpacing: 0,
                color: SlmColors.ivory,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onTick,
          child: VerifyTick(gold: verified, size: 18),
        ),
      ],
    );
  }
}

class _CornerMarks extends StatelessWidget {
  final int score;
  final int deaths;

  const _CornerMarks({required this.score, required this.deaths});

  @override
  Widget build(BuildContext context) {
    final skull = deaths == 0 ? SlmColors.emerald300 : SlmColors.danger;
    final number = TextStyle(
      fontFamily: banglaFont,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: 0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(enDigits('$score'), style: number.copyWith(color: SlmColors.gold200)),
        const SizedBox(width: 12),
        Text('💀', style: number.copyWith(fontSize: 14, color: skull)),
        const SizedBox(width: 4),
        Text(enDigits('$deaths'), style: number.copyWith(color: skull)),
      ],
    );
  }
}

class _PathMark extends StatefulWidget {
  final double shield;
  final bool reduceMotion;
  final String subtitle;
  final VoidCallback onOpen;

  const _PathMark({
    required this.shield,
    required this.reduceMotion,
    required this.subtitle,
    required this.onOpen,
  });

  @override
  State<_PathMark> createState() => _PathMarkState();
}

class _PathMarkState extends State<_PathMark> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onOpen();
      },
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Semantics(
          button: true,
          label: 'মৃত্যুহীন পথ',
          child: Column(
            children: [
              AnimatedSafetyShield(
                size: widget.shield,
                heroTag: widget.reduceMotion ? null : 'slm-home-shield',
              ),
              const SizedBox(height: 18),
              SlmReveal(
                delay: const Duration(milliseconds: 320),
                child: const _HomeTitle(),
              ),
              const SizedBox(height: 6),
              SlmReveal(
                delay: const Duration(milliseconds: 420),
                child: SlmText(
                  widget.subtitle,
                  role: SlmTextRole.bodySm,
                  color: SlmColors.mist,
                  align: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTitle extends StatelessWidget {
  const _HomeTitle();

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle(
      fontFamily: banglaFont,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: 0,
      color: SlmColors.ivory,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'মৃত্যুহীন '),
          TextSpan(text: 'পথ', style: style.copyWith(color: SlmColors.gold300)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
