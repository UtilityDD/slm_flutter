import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_hold.dart';
import '../auth/verify_sheet.dart';
import '../duty_slip/duty_slip_engine.dart';
import '../duty_slip/duty_slip_page.dart';
import '../duty_slip/ladder_focus.dart';
import '../game/beat_fx.dart' show DeathCountChip;
import '../game/game_save.dart';
import '../game/ladder_builder.dart';
import '../rank/league_board.dart';
import '../shell/app_routes.dart';
import '../shell/shell_providers.dart';
import 'home_toolbox.dart';

/// Home → one tap → the ladder (owner's redesign, Nov 2026): ◆ and 💀 with
/// the toolbox, the name with its verify chip, the "continue" card (the next
/// rung, its module's progress and stars), one gold button straight onto the
/// ladder at that rung, and chips for what is waiting (gift chests, league
/// rank) — each shown only when true.
class HomeScreen extends StatefulWidget {
  /// Builds the ladder page for an anchor (null: the current rung). Tests
  /// pass a stand-in; the app uses [ladder].
  final Widget Function(int? anchor)? ladderBuilder;

  const HomeScreen({super.key, this.ladderBuilder});

  /// The ladder, opened at [anchor] (a ladder index) or at the current rung.
  static Widget ladder(int? anchor) => DutySlipPage(startOnRoad: true, anchor: anchor);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// The engine's saved unlock counter (one input of the ladder's focus).
  int? _unlocked;

  /// The catalog is read after Home's first frame, so that frame stays light.
  var _wantLadder = false;

  @override
  void initState() {
    super.initState();
    _loadUnlocked();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _wantLadder = true);
    });
  }

  Future<void> _loadUnlocked() async {
    final u = await DutySlipEngine.savedUnlocked();
    if (mounted && u != _unlocked) setState(() => _unlocked = u);
  }

  void _openLadder(WidgetRef ref, int? anchor) {
    HapticFeedback.lightImpact();
    final build = widget.ladderBuilder ?? HomeScreen.ladder;
    Navigator.of(context)
        .push(SlmPageRoute<void>(builder: (_) => build(anchor), style: SlmTransition.fadeThrough))
        .then((_) {
      if (!mounted) return;
      ref.read(gameSaveProvider.notifier).reloadFromDisk();
      _loadUnlocked();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: SlmTheme.night(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: SlmBackground(constrain: false, child: SizedBox.expand())),
            SafeArea(
              child: Consumer(builder: (context, ref, _) => _body(context, ref)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final save = ref.watch(gameSaveProvider);
    final auth = ref.watch(authProvider);
    final guest = auth.isGuest || !auth.isAuthenticated;
    final verified = !guest && linemanIsVerified(auth, ref.watch(verifyHoldProvider));
    final profile = auth.profile;
    final fullName = profile?.fullName?.trim() ?? '';
    final slmId = profile?.slmId?.trim() ?? '';
    final guestLabel = tr(bn, 'অতিথি', 'Guest');
    final name = guest ? guestLabel : (fullName.isNotEmpty ? fullName : (slmId.isNotEmpty ? slmId : guestLabel));

    final built = _wantLadder ? ref.watch(builtLadderProvider).value : null;
    final unlocked = _unlocked;
    final focus = built == null || unlocked == null ? null : ladderFocus(built, save, unlocked);
    final next = focus == null ? null : ladderNext(built!, save, focus);
    final chests = chestsByLadderIndex(built, save);

    // League rank: verified members with a district only; hidden while
    // loading, offline with no saved board, or when the member is not on it.
    final district = profile?.district?.trim() ?? '';
    int? leagueRank;
    if (verified && !auth.isAdmin && district.isNotEmpty) {
      final rows = ref.watch(leagueBoardProvider((allTime: false, district: district))).value;
      for (final r in rows ?? const <LeagueRow>[]) {
        if (r.isMe && r.rank > 0) leagueRank = r.rank;
      }
    }

    final status = guest
        ? _StatusChip(
            label: tr(bn, 'সাইন ইন করুন', 'Sign in'),
            color: SlmColors.gold200,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.login),
          )
        : verified
            ? _StatusChip(
                label: tr(bn, '✓ যাচাইকৃত', '✓ Verified'),
                color: SlmColors.emerald300,
                onTap: () => showVerifySheet(context),
              )
            : _StatusChip(
                label: tr(bn, '⏳ যাচাই চলছে', '⏳ Verification pending'),
                color: SlmColors.warning,
                onTap: () => showVerifySheet(context),
              );

    final nameLine = SlmReveal(child: _NameLine(name: name, status: status));
    final card = SlmReveal(delay: const Duration(milliseconds: 120), child: _ContinueCard(next: next, bn: bn));
    final button = SlmReveal(
      delay: const Duration(milliseconds: 220),
      child: SlmButton(
        key: const ValueKey('home-go'),
        label: next == null
            ? tr(bn, 'চলুন', "Let's go")
            : next.allDone
                ? tr(bn, 'সিঁড়িতে চলুন', 'Open the ladder')
                : enDigits(tr(bn, 'চলুন, L${next.step}', "Let's go, L${next.step}")),
        variant: SlmButtonVariant.gold,
        size: SlmButtonSize.large,
        trailingIcon: Icons.arrow_forward_rounded,
        expand: true,
        onPressed: () => _openLadder(ref, null),
      ),
    );
    final subtitle = SlmText(
      tr(bn, 'ঘরে আপনার জন্য কেউ অপেক্ষা করছে।', 'Someone at home is waiting for you.'),
      role: SlmTextRole.bodySm,
      color: SlmColors.mist,
      align: TextAlign.center,
    );
    final chips = <Widget>[
      if (chests.isNotEmpty)
        _HomeChip(
          key: const ValueKey('home-chip-gift'),
          label: enDigits(tr(bn, '🎁 ${chests.length}টি উপহার অপেক্ষা করছে', '🎁 ${chests.length} gifts waiting')),
          onTap: () => _openLadder(ref, _nearest(chests.keys, focus ?? 0)),
        ),
      if (leagueRank != null)
        _HomeChip(
          key: const ValueKey('home-chip-league'),
          label: enDigits(tr(bn, '🏆 জেলায় #$leagueRank', '🏆 #$leagueRank in district')),
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.rank),
        ),
    ];
    final chipWrap = chips.isEmpty
        ? const SizedBox.shrink()
        : Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: chips);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              _ScorePill(points: save.points),
              const SizedBox(width: 6),
              DeathCountChip(deaths: save.deaths),
              const Spacer(),
              HomeToolboxButton(onTap: () => openHomeToolbox(context)),
            ],
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final landscape = box.maxWidth > box.maxHeight * 1.3;
                if (landscape) {
                  return Row(
                    children: [
                      Expanded(child: _Fill(child: Column(mainAxisSize: MainAxisSize.min, children: [nameLine, const SizedBox(height: 12), card]))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _Fill(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [button, const SizedBox(height: 10), subtitle, if (chips.isNotEmpty) ...[const SizedBox(height: 10), chipWrap]],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  );
                }
                return _Fill(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        nameLine,
                        const SizedBox(height: 16),
                        card,
                        const SizedBox(height: 16),
                        button,
                        const SizedBox(height: 12),
                        subtitle,
                        if (chips.isNotEmpty) ...[const SizedBox(height: 14), chipWrap],
                      ],
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

  static int _nearest(Iterable<int> indices, int focus) {
    var best = indices.first;
    for (final i in indices) {
      if ((i - focus).abs() < (best - focus).abs()) best = i;
    }
    return best;
  }
}

/// Centres [child] in the space given, scrolling vertically only if it
/// cannot fit (large text, short landscape phones). Width stays ≤ 460.
class _Fill extends StatelessWidget {
  final Widget child;

  const _Fill({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Center(
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: child),
          ),
        ),
      ),
    );
  }
}

/// ◆ total, the same pill as the level top bar (UnifiedGameTopHud).
class _ScorePill extends StatelessWidget {
  final int points;

  const _ScorePill({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E2B45), Color(0xFF111A2E)]),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.65), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('◆', style: TextStyle(color: SlmColors.gold300, fontSize: 13, fontWeight: FontWeight.w900)),
          const SizedBox(width: 5),
          Text(
            enDigits('$points'),
            maxLines: 1,
            softWrap: false,
            style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory, height: 1),
          ),
        ],
      ),
    );
  }
}

class _NameLine extends StatelessWidget {
  final String name;
  final Widget status;

  const _NameLine({required this.name, required this.status});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: bangla(fontSize: 22, fontWeight: FontWeight.w700, color: SlmColors.ivory, height: 1.25),
          ),
        ),
        status,
      ],
    );
  }
}

/// Small pill beside the name: verified, pending (opens the verify sheet) or
/// "sign in" for guests. Its tap area is 48 dp tall.
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SlmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: slmTapTarget, minWidth: slmTapTarget),
        child: Center(
          widthFactor: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(label, maxLines: 1, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w700, color: color, height: 1.2)),
          ),
        ),
      ),
    );
  }
}

/// The hero card: the next rung `L<n>`, its module, the module's progress
/// bar and stars; the all-done message when every open rung is cleared.
class _ContinueCard extends StatelessWidget {
  final LadderNext? next;
  final bool bn;

  const _ContinueCard({required this.next, required this.bn});

  @override
  Widget build(BuildContext context) {
    final n = next;
    final Widget body;
    if (n == null) {
      body = _title(tr(bn, 'মৃত্যুহীন পথ', 'The deathless path'));
    } else if (n.allDone) {
      body = Text(
        tr(bn, 'সব খোলা ধাপ শেষ! নতুন মডিউল শীঘ্রই আসছে', 'Every open step done! New modules coming soon'),
        style: bangla(fontSize: 16, fontWeight: FontWeight.w700, color: SlmColors.ivory, height: 1.35),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                enDigits('L${n.step}'),
                key: const ValueKey('home-step'),
                style: bangla(fontSize: 30, fontWeight: FontWeight.w900, color: SlmColors.gold200, height: 1.1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  enDigits(tr(bn, 'মডিউল ${n.module}', 'Module ${n.module}')),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: SlmColors.mist, height: 1.2),
                ),
              ),
              if (n.starsMax > 0) ...[
                const Icon(Icons.star_rounded, size: 18, color: SlmColors.gold300),
                const SizedBox(width: 2),
                Text(
                  enDigits('${n.stars}/${n.starsMax}'),
                  key: const ValueKey('home-stars'),
                  style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.gold200, height: 1.2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SlmProgressBar(value: n.total == 0 ? 0 : n.cleared / n.total, tone: SlmTone.gold),
          const SizedBox(height: 6),
          Text(
            enDigits(tr(bn, '${n.cleared}/${n.total} ধাপ', '${n.cleared}/${n.total} steps')),
            key: const ValueKey('home-progress'),
            style: bangla(fontSize: 12.5, fontWeight: FontWeight.w600, color: SlmColors.mist, height: 1.2),
          ),
        ],
      );
    }
    return SlmCard(
      variant: SlmCardVariant.gold,
      padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
      child: Row(
        children: [
          // The emblem, still: an idle Home draws no frames.
          const AnimatedSafetyShield(size: 64, animate: false, entrance: false),
          const SizedBox(width: 12),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _title(String text) {
    final style = bangla(fontSize: 24, fontWeight: FontWeight.w700, color: SlmColors.ivory, height: 1.25);
    final parts = text.split(' ');
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: '${parts.first} '),
          TextSpan(text: parts.skip(1).join(' '), style: style.copyWith(color: SlmColors.gold300)),
        ],
      ),
    );
  }
}

/// A "waiting for you" chip under the card; 48 dp tall to tap.
class _HomeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HomeChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SlmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: slmTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: SlmColors.navy850.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.45)),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: SlmColors.gold100, height: 1.2),
          ),
        ),
      ),
    );
  }
}
