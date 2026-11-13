import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/en_digits.dart';
import '../../core/network/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../game/game_save.dart';
import '../home/lesson_progress_store.dart';
import '../rank/league_board.dart';
import '../shell/app_routes.dart';
import '../shell/shell_providers.dart';

/// The server call (`slm_app.delete_my_account()`, supabase/slm_app_30_delete_account.sql).
/// It deletes the shared account, so the website account goes too.
/// Swapped for a fake in tests, so no network is touched.
typedef DeleteAccountCall = Future<Object?> Function();

final deleteAccountCallProvider = Provider<DeleteAccountCall>(
  (ref) => () => SupabaseService.client.schema('slm_app').rpc('delete_my_account'),
);

/// Opens a web page or mail link outside the app. Swappable in tests.
typedef LinkOpener = Future<void> Function(Uri uri);

final linkOpenerProvider = Provider<LinkOpener>((ref) => (uri) async {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    });

Uri supportMailUri() => Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      query: 'subject=${Uri.encodeComponent('Delete my SmartLineman account')}',
    );

enum DeleteAccountOutcome { deleted, adminAccount, failed }

/// Reads the RPC reply: `{'success': true, ...}` or `{'success': false, 'reason': ...}`.
DeleteAccountOutcome readDeleteReply(Object? reply) {
  if (reply is Map && reply['success'] == true) return DeleteAccountOutcome.deleted;
  if (reply is Map && reply['reason'] == 'admin_account') return DeleteAccountOutcome.adminAccount;
  return DeleteAccountOutcome.failed;
}

/// Confirm, delete on the server, then sign out, forget this player on the
/// phone and open the login screen. Nothing changes unless the server said yes.
Future<void> confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final bn = ref.read(languageProvider);
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final deleted = await showGeneralDialog<bool>(
    context: context,
    barrierLabel: 'delete-account',
    barrierColor: SlmColors.navy950.withValues(alpha: 0.88),
    transitionDuration: SlmMotion.slow,
    transitionBuilder: (_, anim, _, child) {
      final t = SlmMotion.emphasized.transform(anim.value);
      return Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
      );
    },
    pageBuilder: (ctx, _, _) => DeleteAccountDialog(
      bn: bn,
      call: ref.read(deleteAccountCallProvider),
      openLink: ref.read(linkOpenerProvider),
    ),
  );
  if (deleted != true) return;
  await forgetDeletedAccount(ref);
  nav.pushNamedAndRemoveUntil(AppRoutes.login, (route) => route.isFirst);
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        tr(bn, 'অ্যাকাউন্ট মুছে ফেলা হয়েছে।', 'Your account has been deleted.'),
        style: bangla(fontSize: 15, fontWeight: FontWeight.w600, color: SlmColors.ivory),
      ),
      backgroundColor: SlmColors.navy900,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// The account is gone on the server: sign out (as logout does) and clear what
/// this phone kept for that player (save, league queue, lesson progress,
/// profile cache). The language choice lives in memory and stays.
Future<void> forgetDeletedAccount(WidgetRef ref) async {
  await ref.read(authProvider.notifier).signOut();
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  } catch (_) {}
  ref.invalidate(gameSaveProvider);
  ref.invalidate(localCompletedLessonsProvider);
  ref.invalidate(readPositionProvider);
  ref.invalidate(myLeagueWinsProvider);
  ref.invalidate(leagueShowNameProvider);
}

enum _Phase { confirm, working, failed, admin }

/// Confirm dialog: the delete button waits 3 seconds so it is never hit by
/// mistake; while the call runs nothing can close it. Pops `true` only when
/// the server deleted the account.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key, required this.bn, required this.call, required this.openLink});

  final bool bn;
  final DeleteAccountCall call;
  final LinkOpener openLink;

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  var _phase = _Phase.confirm;
  var _wait = 3;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _wait--);
      if (_wait <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() => _phase = _Phase.working);
    var outcome = DeleteAccountOutcome.failed;
    try {
      outcome = readDeleteReply(await widget.call());
    } catch (_) {}
    if (!mounted) return;
    switch (outcome) {
      case DeleteAccountOutcome.deleted:
        Navigator.of(context).pop(true);
      case DeleteAccountOutcome.adminAccount:
        setState(() => _phase = _Phase.admin);
      case DeleteAccountOutcome.failed:
        setState(() => _phase = _Phase.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bn = widget.bn;
    final working = _phase == _Phase.working;
    final (title, body) = switch (_phase) {
      _Phase.confirm || _Phase.working => (
          tr(bn, 'অ্যাকাউন্ট মুছবেন?', 'Delete your account?'),
          tr(
            bn,
            'আপনার প্রোফাইল, পয়েন্ট, শেষ করা লেভেল, লিগের সব ফল ও ব্যাজ চিরতরে মুছে যাবে। '
                'এই ফোনে রাখা খেলার তথ্যও মুছে যাবে। এটা আর ফেরানো যাবে না।',
            'Your profile, points, finished levels, all league results and badges will be '
                'deleted for good. Game data saved on this phone is cleared too. This cannot be undone.',
          ),
        ),
      _Phase.failed => (
          tr(bn, 'মোছা গেল না', 'Could not delete'),
          tr(
            bn,
            'ইন্টারনেট নেই বা সার্ভারে সমস্যা। পরে আবার চেষ্টা করুন, অথবা ${AppConfig.supportEmail}-এ লিখুন।',
            'No internet or a server problem. Try again later, or write to ${AppConfig.supportEmail}.',
          ),
        ),
      _Phase.admin => (
          tr(bn, 'মোছা গেল না', 'Could not delete'),
          tr(bn, 'অ্যাডমিন অ্যাকাউন্ট অ্যাপ থেকে মোছা যায় না।', 'Admin accounts cannot be deleted from the app.'),
        ),
    };
    final asking = _phase == _Phase.confirm || working;
    return PopScope(
      canPop: !working,
      child: Center(
        child: Theme(
          data: SlmTheme.night(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      center: Alignment(0, -1.1),
                      radius: 1.3,
                      colors: [SlmColors.navy700, SlmColors.navy900, SlmColors.navy950],
                      stops: [0, 0.5, 1],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.55)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 28, offset: const Offset(0, 12))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SlmIconBadge(icon: Icons.delete_forever_rounded, style: SlmIconStyle.medal, size: 52),
                        const SizedBox(height: SlmSpace.md),
                        SlmText(title, role: SlmTextRole.title, color: SlmColors.ivory, align: TextAlign.center),
                        const SizedBox(height: SlmSpace.xs),
                        SlmText(body, role: SlmTextRole.bodySm, color: SlmColors.mist, align: TextAlign.center, maxLines: 6),
                        const SizedBox(height: SlmSpace.lg),
                        if (asking) ...[
                          SlmButton(
                            label: _wait > 0
                                ? enDigits('${tr(bn, 'হ্যাঁ, মুছুন', 'Yes, delete')} ($_wait)')
                                : tr(bn, 'হ্যাঁ, মুছুন', 'Yes, delete'),
                            variant: SlmButtonVariant.danger,
                            expand: true,
                            loading: working,
                            onPressed: _wait > 0 || working ? null : _delete,
                          ),
                          const SizedBox(height: SlmSpace.xs),
                          SlmButton.ghost(
                            label: tr(bn, 'থাক', 'Keep my account'),
                            expand: true,
                            onPressed: working ? null : () => Navigator.of(context).pop(false),
                          ),
                        ] else ...[
                          if (_phase == _Phase.failed) ...[
                            SlmButton.secondary(
                              label: tr(bn, 'ইমেইল করুন', 'Send an email'),
                              icon: Icons.mail_outline_rounded,
                              expand: true,
                              onPressed: () => widget.openLink(supportMailUri()),
                            ),
                            const SizedBox(height: SlmSpace.xs),
                          ],
                          SlmButton.ghost(
                            label: tr(bn, 'বন্ধ করুন', 'Close'),
                            expand: true,
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                        ],
                      ],
                    ),
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
