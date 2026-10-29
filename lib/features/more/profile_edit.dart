import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../auth/auth_provider.dart';
import '../home/lineman_progress.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';

const profileJobs = <String>[
  'HT-Mobile Van',
  'LT-Mobile Van',
  'HT-LT Others',
  'Substation Operation',
  'Engineer',
  'Non-Technical',
  'Others',
];

Future<Map<String, List<String>>> loadWbPlaces() async {
  final raw = await rootBundle.loadString('assets/data/wb_locations.json');
  final decoded = jsonDecode(raw);
  if (decoded is! Map) return const {};
  final places = <String, List<String>>{};
  for (final entry in decoded.entries) {
    final blocks = entry.value;
    places[entry.key.toString()] = blocks is List
        ? blocks.map((e) => e.toString()).toList()
        : const [];
  }
  return places;
}

Future<bool> saveProfileFields(String id, Map<String, dynamic> fields) async {
  try {
    await SupabaseService.client.from('profiles').update(fields).eq('id', id);
    return true;
  } catch (_) {
    if (!fields.containsKey('phone_number')) return false;
    final next = Map<String, dynamic>.from(fields)..remove('phone_number');
    next['phone'] = fields['phone_number'];
    try {
      await SupabaseService.client.from('profiles').update(next).eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }
}

double _sheetBottom(BuildContext context) {
  final keyboard = MediaQuery.viewInsetsOf(context).bottom;
  if (keyboard > 0) return keyboard;
  final scoped = context.dependOnInheritedWidgetOfExactType<ShellDockScope>();
  return scoped?.bottomInset ?? MediaQuery.paddingOf(context).bottom;
}

Future<void> showNameSheet(BuildContext context, WidgetRef ref) {
  return _showTextSheet(
    context,
    ref,
    titleBn: 'নাম',
    titleEn: 'Name',
    initial: ref.read(authProvider).profile?.fullName ?? '',
    field: 'full_name',
    keyboard: TextInputType.name,
  );
}

Future<void> showPhoneSheet(BuildContext context, WidgetRef ref) {
  return _showTextSheet(
    context,
    ref,
    titleBn: 'ফোন',
    titleEn: 'Phone',
    initial: ref.read(authProvider).profile?.phone ?? '',
    field: 'phone_number',
    keyboard: TextInputType.phone,
  );
}

Future<void> showDistrictSheet(BuildContext context, WidgetRef ref) async {
  final places = await loadWbPlaces();
  if (!context.mounted) return;
  final names = places.keys.toList()..sort();
  final current = ref.read(authProvider).profile?.district;
  final picked = await _showPickSheet(
    context,
    titleBn: 'জেলা',
    titleEn: 'District',
    names: names,
    selected: current,
  );
  if (picked == null || picked == current || !context.mounted) return;
  final ok = await _save(ref, {'district': picked, 'block': null});
  if (!context.mounted) return;
  if (!ok) _fail(context, ref);
}

Future<void> showBlockSheet(BuildContext context, WidgetRef ref) async {
  final profile = ref.read(authProvider).profile;
  final district = profile?.district?.trim() ?? '';
  if (district.isEmpty) return;
  final places = await loadWbPlaces();
  if (!context.mounted) return;
  final names = List<String>.from(places[district] ?? const <String>[]);
  names.sort();
  final picked = await _showPickSheet(
    context,
    titleBn: 'ব্লক',
    titleEn: 'Block',
    names: names,
    selected: profile?.block,
  );
  if (picked == null || !context.mounted) return;
  final ok = await _save(ref, {'block': picked});
  if (!context.mounted) return;
  if (!ok) _fail(context, ref);
}

Future<void> showJobSheet(BuildContext context, WidgetRef ref) async {
  final current = ref.read(authProvider).profile?.job;
  final picked = await _showPickSheet(
    context,
    titleBn: 'কাজ',
    titleEn: 'Job',
    names: profileJobs,
    selected: current,
  );
  if (picked == null || !context.mounted) return;
  final ok = await _save(ref, {'job': picked});
  if (!context.mounted) return;
  if (!ok) _fail(context, ref);
}

Future<bool> _save(WidgetRef ref, Map<String, dynamic> fields) async {
  final id = ref.read(authProvider).profile?.id;
  if (id == null) return false;
  final ok = await saveProfileFields(id, fields);
  if (ok) await ref.read(authProvider.notifier).refreshProfile();
  return ok;
}

void _fail(BuildContext context, WidgetRef ref) {
  final bn = ref.read(languageProvider);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        tr(bn, 'সেভ হয়নি। আবার চেষ্টা করুন।', 'Could not save. Try again.'),
      ),
    ),
  );
}

Future<void> _showTextSheet(
  BuildContext context,
  WidgetRef ref, {
  required String titleBn,
  required String titleEn,
  required String initial,
  required String field,
  required TextInputType keyboard,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _TextSheet(
      titleBn: titleBn,
      titleEn: titleEn,
      initial: initial,
      field: field,
      keyboard: keyboard,
    ),
  );
}

class _TextSheet extends ConsumerStatefulWidget {
  final String titleBn;
  final String titleEn;
  final String initial;
  final String field;
  final TextInputType keyboard;

  const _TextSheet({
    required this.titleBn,
    required this.titleEn,
    required this.initial,
    required this.field,
    required this.keyboard,
  });

  @override
  ConsumerState<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends ConsumerState<_TextSheet> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial,
  );
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _saveText() async {
    final value = _text.text.trim();
    if (value.isEmpty) return;
    setState(() => _saving = true);
    final ok = await _save(ref, {widget.field: value});
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      _fail(context, ref);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: _sheetBottom(context)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(bn, widget.titleBn, widget.titleEn),
                style: bangla(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE7E5E4)),
                ),
                child: TextField(
                  controller: _text,
                  autofocus: true,
                  keyboardType: widget.keyboard,
                  style: bangla(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _saving ? null : _saveText,
                  child: Text(
                    tr(bn, 'সেভ', 'Save'),
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
    );
  }
}

Future<String?> _showPickSheet(
  BuildContext context, {
  required String titleBn,
  required String titleEn,
  required List<String> names,
  required String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PickSheet(
      titleBn: titleBn,
      titleEn: titleEn,
      names: names,
      selected: selected,
    ),
  );
}

class _PickSheet extends ConsumerStatefulWidget {
  final String titleBn;
  final String titleEn;
  final List<String> names;
  final String? selected;

  const _PickSheet({
    required this.titleBn,
    required this.titleEn,
    required this.names,
    required this.selected,
  });

  @override
  ConsumerState<_PickSheet> createState() => _PickSheetState();
}

class _PickSheetState extends ConsumerState<_PickSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final q = _query.text.trim().toLowerCase();
    final shown = q.isEmpty
        ? widget.names
        : widget.names.where((name) => name.toLowerCase().contains(q)).toList();
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return Padding(
      padding: EdgeInsets.only(bottom: _sheetBottom(context)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
                child: Text(
                  tr(bn, widget.titleBn, widget.titleEn),
                  style: bangla(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE7E5E4)),
                  ),
                  child: TextField(
                    controller: _query,
                    onChanged: (_) => setState(() {}),
                    style: bangla(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: tr(bn, 'খুঁজুন', 'Search'),
                      hintStyle: bangla(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: shown.length,
                  itemBuilder: (context, index) {
                    final name = shown[index];
                    final on = name == widget.selected;
                    return ListTile(
                      title: Text(
                        name,
                        style: bangla(
                          fontSize: 16,
                          fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                      trailing: on
                          ? const Icon(
                              Icons.check_rounded,
                              color: Color(0xFFEA580C),
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(name),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CertificatePage extends ConsumerWidget {
  const CertificatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final profile = ref.watch(authProvider).profile;
    final name = profile?.displayName ?? tr(bn, 'লাইনম্যান', 'Lineman');
    final id = profile?.slmId?.trim();
    final level = profile?.trainingLevel ?? 1;
    final badge = linemanBadgeName(level, bn);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SlmBackdrop(
        child: ShellSafeArea(
          child: Padding(
            padding: shellScrollPadding(context, left: 24, top: 4, right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const Spacer(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF5),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFF3D7A1),
                      width: 1.4,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
                    child: Column(
                      children: [
                        Text(
                          tr(bn, 'সার্টিফিকেট', 'Certificate'),
                          style: bangla(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: bangla(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          badge,
                          textAlign: TextAlign.center,
                          style: bangla(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          (id != null && id.isNotEmpty) ? id : '—',
                          style: bangla(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
