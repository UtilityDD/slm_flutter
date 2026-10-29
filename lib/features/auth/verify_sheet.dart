import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../shell/app_routes.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import 'auth_provider.dart';
import 'verify_tick.dart';

const _jobs = <String>[
  'HT-Mobile Van',
  'LT-Mobile Van',
  'HT-LT Others',
  'Substation Operation',
  'Engineer',
  'Non-Technical',
  'Others',
];

Future<void> showVerifySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _VerifyInfo(host: context),
  );
}

double _sheetBottom(BuildContext context) {
  final keyboard = MediaQuery.viewInsetsOf(context).bottom;
  if (keyboard > 0) return keyboard;
  final scoped = context.dependOnInheritedWidgetOfExactType<ShellDockScope>();
  return scoped?.bottomInset ?? MediaQuery.paddingOf(context).bottom;
}

class _VerifyInfo extends ConsumerWidget {
  final BuildContext host;

  const _VerifyInfo({required this.host});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final guest = !ref.watch(authProvider).isAuthenticated;
    final bottom = _sheetBottom(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VerifyTick(size: 36),
                const SizedBox(height: 12),
                Text(
                  tr(bn, 'যাচাই হয়নি', 'Not verified'),
                  textAlign: TextAlign.center,
                  style: bangla(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(
                    bn,
                    'পাঠ ৩ আর খেলা ৫ পর্যন্ত খোলা। বাকি লেভেল যাচাইয়ের পর।',
                    'Lessons through 3 and games through 5 stay open. The rest opens after a check.',
                  ),
                  textAlign: TextAlign.center,
                  style: bangla(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                if (guest) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _openLogin(context),
                      child: Text(
                        tr(bn, 'লগইন', 'Log in'),
                        style: bangla(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openForm(context, ref),
                    child: Text(
                      tr(bn, 'ফর্ম', 'Form'),
                      style: bangla(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _openForm(context, ref),
                      child: Text(
                        tr(bn, 'ফর্ম', 'Form'),
                        style: bangla(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
  }

  void _openLogin(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(host).pushNamed(AppRoutes.login);
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    Navigator.of(context, rootNavigator: true).pop();
    if (!ref.read(authProvider).isAuthenticated) {
      await Navigator.of(host).pushNamed(AppRoutes.login);
      if (!host.mounted) return;
      if (!ref.read(authProvider).isAuthenticated) return;
    }
    if (!host.mounted) return;
    await showModalBottomSheet<void>(
      context: host,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _VerifyForm(),
    );
  }
}

class _VerifyForm extends ConsumerStatefulWidget {
  const _VerifyForm();

  @override
  ConsumerState<_VerifyForm> createState() => _VerifyFormState();
}

class _VerifyFormState extends ConsumerState<_VerifyForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  Map<String, List<String>> _places = const {};
  String? _district;
  String? _block;
  String? _job;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).profile;
    _name.text = profile?.fullName?.trim() ?? '';
    _phone.text = profile?.phone?.trim() ?? '';
    _district = profile?.district;
    _block = profile?.block;
    _job = profile?.job;
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final raw = await rootBundle.loadString('assets/data/wb_locations.json');
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final places = <String, List<String>>{};
      for (final entry in decoded.entries) {
        final blocks = entry.value;
        places[entry.key.toString()] = blocks is List
            ? blocks.map((e) => e.toString()).toList()
            : const [];
      }
      if (!mounted) return;
      setState(() {
        _places = places;
        if (_district != null && !places.containsKey(_district))
          _district = null;
        final blocks = places[_district] ?? const <String>[];
        if (_block != null && !blocks.contains(_block)) _block = null;
        if (_job != null && !_jobs.contains(_job)) _job = null;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final bn = ref.read(languageProvider);
    final auth = ref.read(authProvider);
    final id = auth.profile?.id;
    if (id == null || auth.profile?.isGuest == true) return;
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty ||
        _district == null ||
        _block == null ||
        _job == null ||
        phone.isEmpty) {
      setState(() => _error = tr(bn, 'সব ঘর পূরণ করুন।', 'Fill every field.'));
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final payload = <String, dynamic>{
      'full_name': name,
      'district': _district,
      'block': _block,
      'job': _job,
      'phone_number': phone,
    };
    try {
      await _save(id, payload);
    } catch (_) {
      try {
        payload.remove('phone_number');
        payload['phone'] = phone;
        await _save(id, payload);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _sending = false;
          _error = tr(
            bn,
            'পাঠানো যায়নি। আবার চেষ্টা করুন।',
            'Could not send. Try again.',
          );
        });
        return;
      }
    }
    await ref.read(authProvider.notifier).refreshProfile();
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = true;
    });
  }

  Future<void> _save(String id, Map<String, dynamic> payload) {
    return SupabaseService.client.from('profiles').update(payload).eq('id', id);
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final bottom = _sheetBottom(context);
    final districts = _places.keys.toList()..sort();
    final blocks = _places[_district] ?? const <String>[];

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr(bn, 'ফর্ম', 'Form'),
                  style: bangla(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 14),
                _box(
                  child: TextField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    style: bangla(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    decoration: _deco(tr(bn, 'নাম', 'Name')),
                  ),
                ),
                const SizedBox(height: 10),
                _box(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('district-$_district-${districts.length}'),
                    initialValue: districts.contains(_district)
                        ? _district
                        : null,
                    isExpanded: true,
                    decoration: _deco(tr(bn, 'জেলা', 'District')),
                    items: [
                      for (final name in districts)
                        DropdownMenuItem(value: name, child: Text(name)),
                    ],
                    onChanged: (value) => setState(() {
                      _district = value;
                      _block = null;
                    }),
                  ),
                ),
                const SizedBox(height: 10),
                _box(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('block-$_district-$_block-${blocks.length}'),
                    initialValue: blocks.contains(_block) ? _block : null,
                    isExpanded: true,
                    decoration: _deco(tr(bn, 'ব্লক', 'Block')),
                    items: [
                      for (final name in blocks)
                        DropdownMenuItem(value: name, child: Text(name)),
                    ],
                    onChanged: _district == null
                        ? null
                        : (value) => setState(() => _block = value),
                  ),
                ),
                const SizedBox(height: 10),
                _box(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('job-$_job'),
                    initialValue: _jobs.contains(_job) ? _job : null,
                    isExpanded: true,
                    decoration: _deco(tr(bn, 'কাজ', 'Job')),
                    items: [
                      for (final name in _jobs)
                        DropdownMenuItem(value: name, child: Text(name)),
                    ],
                    onChanged: (value) => setState(() => _job = value),
                  ),
                ),
                const SizedBox(height: 10),
                _box(
                  child: TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    style: bangla(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    decoration: _deco(tr(bn, 'ফোন', 'Phone')),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: bangla(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.alertRed,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _sending || _sent ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            tr(
                              bn,
                              _sent ? 'পাঠানো হয়েছে' : 'পাঠান',
                              _sent ? 'Sent' : 'Send',
                            ),
                            style: bangla(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
  }

  Widget _box({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: child,
    );
  }

  InputDecoration _deco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: bangla(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
      ),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    );
  }
}
