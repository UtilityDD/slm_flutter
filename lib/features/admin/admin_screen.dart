import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../auth/verify_tick.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import 'dev_unlock.dart';

class _Person {
  final String id;
  final String name;
  final String? email;
  final String role;
  final String? district;
  final bool verified;
  final bool blocked;

  const _Person({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.district,
    this.verified = true,
    this.blocked = false,
  });

  factory _Person.fromMap(Map<String, dynamic> row) {
    final name = row['full_name']?.toString().trim();
    final slm = row['slm_id']?.toString().trim();
    return _Person(
      id: row['id']?.toString() ?? '',
      name: (name != null && name.isNotEmpty)
          ? name
          : (slm != null && slm.isNotEmpty ? slm : 'লাইনম্যান'),
      email: row['email']?.toString(),
      role: row['role']?.toString().trim().isNotEmpty == true
          ? row['role'].toString()
          : 'pending',
      district: row['district']?.toString(),
      verified: row.containsKey('verified') ? row['verified'] == true : true,
      blocked: row['blocked'] == true,
    );
  }
}

const _roleChoices = <(String, String, String)>[
  ('pending', 'অপেক্ষমাণ', 'Pending'),
  ('lineman', 'লাইনম্যান', 'Lineman'),
  ('supervisor', 'সুপারভাইজার', 'Supervisor'),
];

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  List<_Person> _people = const [];
  bool _loading = true;
  String? _note;
  String? _busyId;
  String _query = '';
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _note = null;
    });
    try {
      final rows = await SupabaseService.client.rpc('admin_list_people');
      final people = (rows as List)
          .map((row) => _Person.fromMap(Map<String, dynamic>.from(row as Map)))
          .where((p) => p.id.isNotEmpty)
          .toList();
      if (!mounted) return;
      final marked = await _withVerified(people);
      if (!mounted) return;
      setState(() {
        _people = marked;
        _loading = false;
      });
    } catch (_) {
      try {
        final rows = await SupabaseService.client
            .from('profiles')
            .select('id, full_name, slm_id, role, district')
            .order('full_name')
            .limit(200);
        final people = rows
            .map(_Person.fromMap)
            .where((p) => p.id.isNotEmpty)
            .toList();
        if (!mounted) return;
        final marked = await _withVerified(people);
        if (!mounted) return;
        setState(() {
          _people = marked;
          _loading = false;
          _note = 'পুরো তালিকা দেখতে supabase/admin_access.sql একবার চালান।';
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _note = 'তালিকা লোড হয়নি।';
        });
      }
    }
  }

  Future<List<_Person>> _withVerified(List<_Person> people) async {
    try {
      List rows;
      var hasBlocked = true;
      try {
        rows = await SupabaseService.client.from('profiles').select('id, verified, blocked');
      } catch (_) {
        hasBlocked = false;
        rows = await SupabaseService.client.from('profiles').select('id, verified');
      }
      final flags = <String, bool>{};
      final blocks = <String, bool>{};
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw as Map);
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        flags[id] = row['verified'] == true;
        if (hasBlocked) blocks[id] = row['blocked'] == true;
      }
      return [
        for (final person in people)
          _Person(
            id: person.id,
            name: person.name,
            email: person.email,
            role: person.role,
            district: person.district,
            verified: flags[person.id] ?? person.verified,
            blocked: hasBlocked ? (blocks[person.id] ?? false) : person.blocked,
          ),
      ];
    } catch (_) {
      return people;
    }
  }

  Future<void> _setVerified(_Person person, bool verified) async {
    setState(() => _busyId = person.id);
    try {
      await SupabaseService.client.rpc(
        'admin_set_verified',
        params: {'p_user_id': person.id, 'p_verified': verified},
      );
      if (!mounted) return;
      setState(() {
        _people = [
          for (final p in _people)
            p.id == person.id
                ? _Person(
                    id: p.id,
                    name: p.name,
                    email: p.email,
                    role: p.role,
                    district: p.district,
                    verified: verified,
                    blocked: p.blocked,
                  )
                : p,
        ];
        _busyId = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busyId = null;
        _note = 'টিক বদলাতে supabase/verify_lineman.sql একবার চালান।';
      });
    }
  }

  Future<void> _askRole(_Person person, String role, bool bn) async {
    final choice = _roleChoices.firstWhere((c) => c.$1 == role);
    final label = tr(bn, choice.$2, choice.$3);
    final go = await showGeneralDialog<bool>(
      context: context,
      barrierLabel: 'role',
      barrierColor: SlmColors.navy950.withValues(alpha: 0.88),
      transitionDuration: SlmMotion.slow,
      transitionBuilder: (_, anim, _, child) {
        final t = SlmMotion.emphasized.transform(anim.value);
        return Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child),
        );
      },
      pageBuilder: (ctx, _, _) => Center(
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
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [SlmColors.navy800, SlmColors.navy950],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.55)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SlmText(person.name, role: SlmTextRole.title, color: SlmColors.ivory, align: TextAlign.center, maxLines: 2),
                        const SizedBox(height: SlmSpace.xs),
                        SlmText(
                          tr(bn, 'রোল হবে $label। অ্যাকাউন্ট এখনই বদলাবে।', 'Role becomes $label. The account updates now.'),
                          role: SlmTextRole.bodySm,
                          color: SlmColors.mist,
                          align: TextAlign.center,
                          maxLines: 3,
                        ),
                        const SizedBox(height: SlmSpace.lg),
                        SlmButton.gold(
                          label: tr(bn, 'বদলান', 'Change'),
                          expand: true,
                          onPressed: () => Navigator.of(ctx).pop(true),
                        ),
                        const SizedBox(height: SlmSpace.xs),
                        SlmButton.ghost(
                          label: tr(bn, 'থাক', 'Keep'),
                          expand: true,
                          onPressed: () => Navigator.of(ctx).pop(false),
                        ),
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
    if (go == true) await _setRole(person, role);
  }

  Future<void> _setRole(_Person person, String role) async {
    setState(() => _busyId = person.id);
    try {
      await SupabaseService.client.rpc(
        'admin_set_role',
        params: {'p_user_id': person.id, 'p_role': role},
      );
      if (!mounted) return;
      setState(() {
        _people = [
          for (final p in _people)
            p.id == person.id
                ? _Person(
                    id: p.id,
                    name: p.name,
                    email: p.email,
                    role: role,
                    district: p.district,
                    verified: p.verified,
                    blocked: p.blocked,
                  )
                : p,
        ];
        _busyId = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busyId = null;
        _note = 'রোল বদলাতে supabase/admin_access.sql একবার চালান।';
      });
    }
  }

  Future<void> _askVerify(_Person person, bool bn) async {
    final turningOn = !person.verified;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: SlmTheme.night(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [SlmColors.navy800, SlmColors.navy950],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.55)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlmText(person.name, role: SlmTextRole.title, color: SlmColors.ivory, align: TextAlign.center, maxLines: 2),
                    const SizedBox(height: SlmSpace.xs),
                    SlmText(
                      turningOn
                          ? tr(bn, 'টিক সোনালি হবে। পয়েন্ট, পাঠ ও ওয়েব খেলা আগের মতো থাকবে।', 'The tick turns gold. Points, lessons, and web play stay as they are.')
                          : tr(bn, 'টিক ধূসর হবে। পয়েন্ট, পাঠ ও ওয়েব খেলা আগের মতো থাকবে।', 'The tick turns grey. Points, lessons, and web play stay as they are.'),
                      role: SlmTextRole.bodySm,
                      color: SlmColors.mist,
                      align: TextAlign.center,
                      maxLines: 4,
                    ),
                    const SizedBox(height: SlmSpace.lg),
                    SlmButton(
                      label: turningOn ? tr(bn, 'যাচাই করুন', 'Verify') : tr(bn, 'যাচাই তুলুন', 'Unverify'),
                      variant: turningOn ? SlmButtonVariant.gold : SlmButtonVariant.secondary,
                      expand: true,
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                    const SizedBox(height: SlmSpace.xs),
                    SlmButton.ghost(
                      label: tr(bn, 'থাক', 'Keep'),
                      expand: true,
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (go == true) await _setVerified(person, turningOn);
  }

  bool _canBlock(_Person person) {
    final mail = person.email?.trim().toLowerCase();
    if (mail != null && AppConfig.adminEmails.contains(mail)) return false;
    final me = ref.read(authProvider).profile?.id;
    return me == null || me != person.id;
  }

  Future<void> _askBlock(_Person person, bool bn) async {
    final blocking = !person.blocked;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: SlmTheme.night(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [SlmColors.navy800, SlmColors.navy950],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: SlmColors.danger.withValues(alpha: 0.7)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlmText(person.name, role: SlmTextRole.title, color: SlmColors.ivory, align: TextAlign.center, maxLines: 2),
                    const SizedBox(height: SlmSpace.xs),
                    SlmText(
                      blocking
                          ? tr(bn, 'এই অ্যাকাউন্ট বন্ধ হবে। সে আর ঢুকতে পারবে না।', 'This account will be blocked and cannot sign in.')
                          : tr(bn, 'এই অ্যাকাউন্ট আবার খুলবে।', 'This account can sign in again.'),
                      role: SlmTextRole.bodySm,
                      color: SlmColors.mist,
                      align: TextAlign.center,
                      maxLines: 3,
                    ),
                    const SizedBox(height: SlmSpace.lg),
                    SlmButton(
                      label: blocking ? tr(bn, 'ব্লক করুন', 'Block') : tr(bn, 'আনব্লক', 'Unblock'),
                      variant: blocking ? SlmButtonVariant.danger : SlmButtonVariant.gold,
                      expand: true,
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                    const SizedBox(height: SlmSpace.xs),
                    SlmButton.ghost(
                      label: tr(bn, 'থাক', 'Keep'),
                      expand: true,
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (go == true) await _setBlocked(person, blocking);
  }

  Future<void> _setBlocked(_Person person, bool blocked) async {
    setState(() => _busyId = person.id);
    try {
      await SupabaseService.client.rpc(
        'admin_set_blocked',
        params: {'p_user_id': person.id, 'p_blocked': blocked},
      );
      if (!mounted) return;
      setState(() {
        _people = [
          for (final p in _people)
            p.id == person.id
                ? _Person(
                    id: p.id,
                    name: p.name,
                    email: p.email,
                    role: p.role,
                    district: p.district,
                    verified: p.verified,
                    blocked: blocked,
                  )
                : p,
        ];
        _busyId = null;
        _note = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busyId = null;
        _note = 'ব্লক চালু করতে supabase/block_user.sql একবার চালান।';
      });
    }
  }

  List<_Person> get _shown {
    final q = _query.trim().toLowerCase();
    return [
      for (final person in _people)
        if (_filter == 'all' ||
            (_filter == 'pending' && person.role == 'pending') ||
            (_filter == 'verified' && person.verified) ||
            (_filter == 'unverified' && !person.verified) ||
            (_filter == 'blocked' && person.blocked))
          if (q.isEmpty ||
              person.name.toLowerCase().contains(q) ||
              (person.email ?? '').toLowerCase().contains(q) ||
              (person.district ?? '').toLowerCase().contains(q))
            person,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final admin = ref.watch(authProvider).isAdmin;
    final devOn = ref.watch(devUnlockProvider);
    final pending = _people.where((p) => p.role == 'pending').length;
    final verified = _people.where((p) => p.verified).length;
    final unverified = _people.where((p) => !p.verified).length;
    final blocked = _people.where((p) => p.blocked).length;
    final shown = _shown;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: SlmTheme.night(),
        child: Builder(
          builder: (context) {
            final g = context.slm.layout.gutter;
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(child: SlmBackground(constrain: false, child: SizedBox.expand())),
                  ShellSafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(4, 4, g, 0),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.of(context).maybePop(),
                                tooltip: tr(bn, 'ফিরে যান', 'Back'),
                                icon: const Icon(Icons.arrow_back_rounded, color: SlmColors.ivory),
                              ),
                              Expanded(
                                child: SlmText(tr(bn, 'অ্যাডমিন', 'Admin'), role: SlmTextRole.headline, color: SlmColors.ivory),
                              ),
                              if (admin)
                                IconButton(
                                  onPressed: _loading ? null : _load,
                                  tooltip: tr(bn, 'রিফ্রেশ', 'Refresh'),
                                  icon: const Icon(Icons.refresh_rounded, color: SlmColors.gold300),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: admin
                              ? ListView(
                                  padding: shellScrollPadding(context, left: g, top: 4, right: g, extraBottom: 16),
                                  children: [
                                    _Panel(
                                      child: SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          tr(bn, 'ডেভেলপার', 'Developer'),
                                          style: bangla(fontSize: 16, fontWeight: FontWeight.w700, color: SlmColors.ivory),
                                        ),
                                        subtitle: Text(
                                          tr(
                                            bn,
                                            'সব অধ্যায়, পাঠ, মৃত্যুহীন লেভেল ও জিরো লস ডিউটি খুলবে। শুধু এই ফোনে।',
                                            'Opens every chapter, lesson, duty-slip level, and Zero Loss duty. This phone only.',
                                          ),
                                          style: bangla(fontSize: 13, fontWeight: FontWeight.w500, color: SlmColors.mist, height: 1.35),
                                        ),
                                        value: devOn,
                                        activeThumbColor: SlmColors.gold300,
                                        activeTrackColor: SlmColors.gold700,
                                        onChanged: (value) => ref.read(devUnlockProvider.notifier).setOn(value),
                                      ),
                                    ),
                                    const SizedBox(height: SlmSpace.lg),
                                    SlmSectionHeader(title: tr(bn, 'অনুমোদন', 'Authorization')),
                                    SlmText(
                                      tr(bn, 'যাচাই শুধু টিক বদলায়। পয়েন্ট, পাঠ ও ওয়েব খেলা আগের মতো থাকে।', 'Verify only changes the tick. Points, lessons, and web play stay as they are.'),
                                      role: SlmTextRole.bodySm,
                                      color: SlmColors.mist,
                                    ),
                                    const SizedBox(height: SlmSpace.md),
                                    Row(
                                      children: [
                                        _Count(label: tr(bn, 'মোট', 'All'), value: _people.length, on: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                                        const SizedBox(width: SlmSpace.xs),
                                        _Count(label: tr(bn, 'যাচাই', 'Verified'), value: verified, on: _filter == 'verified', tone: SlmColors.emerald300, onTap: () => setState(() => _filter = 'verified')),
                                        const SizedBox(width: SlmSpace.xs),
                                        _Count(label: tr(bn, 'অযাচাই', 'Unverified'), value: unverified, on: _filter == 'unverified', tone: SlmColors.slate, onTap: () => setState(() => _filter = 'unverified')),
                                      ],
                                    ),
                                    const SizedBox(height: SlmSpace.xs),
                                    Row(
                                      children: [
                                        _Count(label: tr(bn, 'অপেক্ষমাণ', 'Pending'), value: pending, on: _filter == 'pending', tone: SlmColors.gold300, onTap: () => setState(() => _filter = 'pending')),
                                        const SizedBox(width: SlmSpace.xs),
                                        _Count(label: tr(bn, 'ব্লক', 'Blocked'), value: blocked, on: _filter == 'blocked', tone: SlmColors.danger, onTap: () => setState(() => _filter = 'blocked')),
                                        const SizedBox(width: SlmSpace.xs),
                                        const Expanded(child: SizedBox.shrink()),
                                      ],
                                    ),
                                    const SizedBox(height: SlmSpace.sm),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: SlmColors.navy900,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.45)),
                                      ),
                                      child: TextField(
                                        onChanged: (value) => setState(() => _query = value),
                                        cursorColor: SlmColors.gold400,
                                        style: bangla(fontSize: 16, fontWeight: FontWeight.w600, color: SlmColors.ivory),
                                        decoration: InputDecoration(
                                          hintText: tr(bn, 'নাম, ইমেল বা জেলা', 'Name, email or district'),
                                          hintStyle: bangla(fontSize: 15, fontWeight: FontWeight.w500, color: SlmColors.slate),
                                          prefixIcon: const Icon(Icons.search_rounded, color: SlmColors.gold300),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                        ),
                                      ),
                                    ),
                                    if (_note != null) ...[
                                      const SizedBox(height: SlmSpace.sm),
                                      _Panel(
                                        edge: SlmColors.danger,
                                        child: SlmText(_note!, role: SlmTextRole.bodySm, color: const Color(0xFFFCA5A5), maxLines: 4),
                                      ),
                                    ],
                                    const SizedBox(height: SlmSpace.md),
                                    if (_loading)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 28),
                                        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: SlmColors.gold300)),
                                      )
                                    else if (shown.isEmpty)
                                      SlmEmptyState(
                                        icon: Icons.person_search_rounded,
                                        title: tr(bn, 'কাউকে পাওয়া যায়নি', 'No one matches'),
                                      )
                                    else
                                      for (final person in shown) ...[
                                        _PersonCard(
                                          person: person,
                                          bn: bn,
                                          busy: _busyId == person.id,
                                          onVerify: () => _askVerify(person, bn),
                                          onRole: (role) => _askRole(person, role, bn),
                                          onBlock: _canBlock(person) ? () => _askBlock(person, bn) : null,
                                        ),
                                        const SizedBox(height: SlmSpace.sm),
                                      ],
                                  ],
                                )
                              : Center(
                                  child: SlmEmptyState(
                                    icon: Icons.lock_rounded,
                                    title: tr(bn, 'এই অ্যাকাউন্টে অ্যাডমিন নেই।', 'This account is not an admin.'),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final String label;
  final int value;
  final bool on;
  final Color tone;
  final VoidCallback onTap;

  const _Count({
    required this.label,
    required this.value,
    required this.on,
    required this.onTap,
    this.tone = SlmColors.ivory,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SlmPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: SlmMotion.fast,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: on ? SlmGradients.navyCard : null,
            color: on ? null : SlmColors.navy900.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: (on ? SlmColors.gold400 : SlmColors.navy600).withValues(alpha: on ? 0.8 : 0.5)),
          ),
          child: Column(
            children: [
              Text('$value', style: context.slm.type.number.copyWith(color: on ? SlmColors.gold300 : tone, fontSize: 18)),
              const SizedBox(height: 2),
              SlmText(label, role: SlmTextRole.caption, color: on ? SlmColors.gold100 : SlmColors.mist, maxLines: 1, align: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final _Person person;
  final bool bn;
  final bool busy;
  final VoidCallback onVerify;
  final ValueChanged<String> onRole;
  final VoidCallback? onBlock;

  const _PersonCard({
    required this.person,
    required this.bn,
    required this.busy,
    required this.onVerify,
    required this.onRole,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: busy ? 0.55 : 1,
      child: _Panel(
        edge: person.blocked ? SlmColors.danger : SlmColors.gold400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: SlmText(person.name, role: SlmTextRole.titleSm, color: SlmColors.ivory, maxLines: 1)),
                if (busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: SlmColors.gold300),
                  ),
              ],
            ),
            if (person.email != null && person.email!.isNotEmpty) ...[
              const SizedBox(height: 2),
              SlmText(person.email!, role: SlmTextRole.caption, color: SlmColors.gold300, maxLines: 1),
            ],
            if (person.district != null && person.district!.isNotEmpty)
              SlmText(person.district!, role: SlmTextRole.caption, color: SlmColors.mist, maxLines: 1),
            const SizedBox(height: SlmSpace.sm),
            Row(
              children: [
                VerifyTick(gold: person.verified, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: SlmText(
                    person.verified ? tr(bn, 'যাচাই করা', 'Verified') : tr(bn, 'যাচাই হয়নি', 'Not verified'),
                    role: SlmTextRole.label,
                    color: person.verified ? SlmColors.emerald300 : SlmColors.slate,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SlmSpace.sm),
            SlmButton(
              label: person.verified ? tr(bn, 'যাচাই তুলুন', 'Unverify') : tr(bn, 'যাচাই করুন', 'Verify'),
              variant: person.verified ? SlmButtonVariant.secondary : SlmButtonVariant.gold,
              size: SlmButtonSize.small,
              expand: true,
              onPressed: busy ? null : onVerify,
            ),
            const SizedBox(height: SlmSpace.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final choice in _roleChoices)
                  SlmChip(
                    label: tr(bn, choice.$2, choice.$3),
                    tone: choice.$1 == 'pending' ? SlmTone.gold : (choice.$1 == 'supervisor' ? SlmTone.emerald : SlmTone.navy),
                    selected: person.role == choice.$1,
                    onTap: busy || person.role == choice.$1 ? null : () => onRole(choice.$1),
                  ),
              ],
            ),
            if (onBlock != null) ...[
              const SizedBox(height: SlmSpace.sm),
              SlmButton(
                label: person.blocked ? tr(bn, 'আনব্লক', 'Unblock') : tr(bn, 'ব্লক', 'Block'),
                variant: person.blocked ? SlmButtonVariant.secondary : SlmButtonVariant.danger,
                size: SlmButtonSize.small,
                expand: true,
                onPressed: busy ? null : onBlock,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final Color edge;

  const _Panel({required this.child, this.edge = SlmColors.gold400});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: SlmGradients.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: edge.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}
