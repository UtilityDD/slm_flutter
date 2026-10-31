import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/slm_backdrop.dart';
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

  const _Person({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.district,
    this.verified = true,
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
      final rows = await SupabaseService.client
          .from('profiles')
          .select('id, verified');
      final flags = <String, bool>{};
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw as Map);
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        flags[id] = row['verified'] == true;
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
                    verified: role != 'pending',
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

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final admin = ref.watch(authProvider).isAdmin;
    final devOn = ref.watch(devUnlockProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SlmBackdrop(
        child: ShellSafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: tr(bn, 'ফিরে যান', 'Back'),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.ink,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tr(bn, 'অ্যাডমিন', 'Admin'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: admin
                    ? ListView(
                        padding: shellScrollPadding(
                          context,
                          left: 16,
                          top: 8,
                          right: 16,
                          extraBottom: 16,
                        ),
                        children: [
                          _Card(
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                tr(bn, 'ডেভেলপার', 'Developer'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                tr(
                                  bn,
                                  'সব অধ্যায়, পাঠ, মৃত্যুহীন লেভেল ও জিরো লস ডিউটি খুলবে। শুধু এই ফোনে।',
                                  'Opens every chapter, lesson, duty-slip level, and Zero Loss duty. This phone only.',
                                ),
                              ),
                              value: devOn,
                              activeThumbColor: const Color(0xFF0F766E),
                              onChanged: (value) {
                                ref
                                    .read(devUnlockProvider.notifier)
                                    .setOn(value);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tr(bn, 'অনুমোদন', 'Authorization'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr(
                              bn,
                              'রোল বদলালে সেই সদস্যের অ্যাকাউন্ট বদলায়।',
                              'Changing a role updates that member’s account.',
                            ),
                            style: const TextStyle(
                              color: AppColors.muted,
                              height: 1.35,
                            ),
                          ),
                          if (_note != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _note!,
                              style: const TextStyle(
                                color: AppColors.alertRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (_loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else if (_people.isEmpty)
                            Text(tr(bn, 'এখন কেউ নেই।', 'Nobody yet.'))
                          else
                            for (final person in _people) ...[
                              _Card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      person.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: _busyId == person.id
                                          ? null
                                          : () => _setVerified(
                                              person,
                                              !person.verified,
                                            ),
                                      child: VerifyTick(
                                        gold: person.verified,
                                        size: 22,
                                      ),
                                    ),
                                    if (person.email != null &&
                                        person.email!.isNotEmpty)
                                      Text(
                                        person.email!,
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    if (person.district != null &&
                                        person.district!.isNotEmpty)
                                      Text(
                                        person.district!,
                                        style: const TextStyle(
                                          color: AppColors.inkSoft,
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final choice in _roleChoices)
                                          ChoiceChip(
                                            label: Text(
                                              tr(bn, choice.$2, choice.$3),
                                            ),
                                            selected: person.role == choice.$1,
                                            onSelected: _busyId == person.id
                                                ? null
                                                : (selected) {
                                                    if (selected &&
                                                        person.role !=
                                                            choice.$1)
                                                      _setRole(
                                                        person,
                                                        choice.$1,
                                                      );
                                                  },
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                        ],
                      )
                    : Center(
                        child: Text(
                          tr(
                            bn,
                            'এই অ্যাকাউন্টে অ্যাডমিন নেই।',
                            'This account is not an admin.',
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33D6D3D1)),
      ),
      child: child,
    );
  }
}
