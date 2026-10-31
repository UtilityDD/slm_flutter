import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';

class EmergencyServiceItem {
  final String id;
  final String name;
  final String type;
  final String district;
  final String location;
  final String phone;
  final String? address;

  const EmergencyServiceItem({
    required this.id,
    required this.name,
    required this.type,
    required this.district,
    required this.location,
    required this.phone,
    this.address,
  });

  factory EmergencyServiceItem.fromJson(Map<String, dynamic> json) {
    return EmergencyServiceItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'emergency',
      district: json['district']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString(),
    );
  }
}

class _Group {
  final String id;
  final String bn;
  final String en;
  final IconData icon;
  final Color color;

  const _Group(this.id, this.bn, this.en, this.icon, this.color);
}

const _immediate = <_Group>[
  _Group(
    'ambulance',
    'অ্যাম্বুলেন্স',
    'Ambulance',
    Icons.airport_shuttle_rounded,
    AppColors.safeGreen,
  ),
  _Group(
    'fire',
    'ফায়ার',
    'Fire',
    Icons.local_fire_department_rounded,
    AppColors.safetyOrange,
  ),
  _Group(
    'police',
    'পুলিশ',
    'Police',
    Icons.local_police_rounded,
    AppColors.electricBlue,
  ),
  _Group(
    'power',
    'বিদ্যুৎ জরুরি',
    'Electricity emergency',
    Icons.electric_bolt_rounded,
    AppColors.primaryDarkAmber,
  ),
];

const _hospitals = _Group(
  'hospitals',
  'হাসপাতাল',
  'Hospitals',
  Icons.local_hospital_rounded,
  Color(0xFF0F766E),
);

const _other = _Group(
  'other',
  'অন্যান্য',
  'Other',
  Icons.forum_rounded,
  AppColors.muted,
);

const _groupOrder = [
  'ambulance',
  'fire',
  'police',
  'power',
  'hospitals',
  'other',
];

String _bucket(String type) {
  final t = type.toLowerCase();
  if (t.contains('ambulance')) return 'ambulance';
  if (t.contains('fire')) return 'fire';
  if (t.contains('police')) return 'police';
  if (t.contains('power') || t.contains('electric')) return 'power';
  if (t.contains('hospital') || t.contains('health')) return 'hospitals';
  return 'other';
}

_Group _groupFor(String id) {
  for (final group in _immediate) {
    if (group.id == id) return group;
  }
  if (id == _hospitals.id) return _hospitals;
  return _other;
}

String _shownName(String raw) =>
    raw.replaceAll('&#038;', '&').replaceAll('&amp;', '&');

class EmergencyDirectoryScreen extends ConsumerStatefulWidget {
  const EmergencyDirectoryScreen({super.key});

  @override
  ConsumerState<EmergencyDirectoryScreen> createState() =>
      _EmergencyDirectoryScreenState();
}

class _EmergencyDirectoryScreenState
    extends ConsumerState<EmergencyDirectoryScreen> {
  List<EmergencyServiceItem> _allServices = [];
  List<String> _districts = const [];
  String _selectedDistrict = '';
  String _searchQuery = '';
  String? _kind;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmergencyData();
  }

  Future<void> _loadEmergencyData() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/districtEmergencyServices.json',
      );
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final items = jsonList
          .map((e) => EmergencyServiceItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final districtSet = <String>{};
      for (final item in items) {
        if (item.district.trim().isNotEmpty) {
          districtSet.add(item.district.trim());
        }
      }
      final sortedDistricts = districtSet.toList()..sort();
      if (!mounted) return;
      setState(() {
        _allServices = items;
        _districts = sortedDistricts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<EmergencyServiceItem> _scoped() {
    if (_selectedDistrict.isEmpty) return _allServices;
    return [
      for (final item in _allServices)
        if (item.district == _selectedDistrict) item,
    ];
  }

  List<EmergencyServiceItem> _matched(List<EmergencyServiceItem> source) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return source;
    return [
      for (final item in source)
        if (item.name.toLowerCase().contains(q) ||
            item.phone.contains(q) ||
            item.location.toLowerCase().contains(q) ||
            item.type.toLowerCase().contains(q))
          item,
    ];
  }

  int _count(String id) {
    var n = 0;
    for (final item in _matched(_scoped())) {
      if (_bucket(item.type) == id) n++;
    }
    return n;
  }

  bool get _showPicker => _kind == null && _searchQuery.trim().isEmpty;

  void _selectKind(String id) {
    setState(() => _kind = _kind == id ? null : id);
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SlmBackdrop(
        child: ShellSafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(bn: bn),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    children: [
                      _DistrictField(
                        bn: bn,
                        districts: _districts,
                        value: _selectedDistrict,
                        onChanged: (value) {
                          setState(() => _selectedDistrict = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      _SearchField(
                        bn: bn,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: _showPicker ? _picker(bn) : _results(bn)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _picker(bool bn) {
    final otherCount = _count(_other.id);
    return ListView(
      padding: shellScrollPadding(
        context,
        left: 20,
        top: 0,
        right: 20,
        extraBottom: 16,
      ),
      children: [
        _SectionLabel(tr(bn, 'এখনই কল', 'Call now')),
        const SizedBox(height: 8),
        for (final group in _immediate) ...[
          _GroupRow(
            label: tr(bn, group.bn, group.en),
            detail: tr(
              bn,
              '${_count(group.id)} টি নম্বর',
              '${_count(group.id)} numbers',
            ),
            icon: group.icon,
            color: group.color,
            selected: false,
            onTap: () => _selectKind(group.id),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        _SectionLabel(tr(bn, 'অন্যান্য যোগাযোগ', 'Other contacts')),
        const SizedBox(height: 8),
        _GroupRow(
          label: tr(bn, _hospitals.bn, _hospitals.en),
          detail: tr(
            bn,
            '${_count(_hospitals.id)} টি নম্বর',
            '${_count(_hospitals.id)} numbers',
          ),
          icon: _hospitals.icon,
          color: _hospitals.color,
          selected: false,
          onTap: () => _selectKind(_hospitals.id),
        ),
        if (otherCount > 0) ...[
          const SizedBox(height: 10),
          _GroupRow(
            label: tr(bn, _other.bn, _other.en),
            detail: tr(bn, '$otherCount টি নম্বর', '$otherCount numbers'),
            icon: _other.icon,
            color: _other.color,
            selected: false,
            onTap: () => _selectKind(_other.id),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          tr(
            bn,
            'জেলা বেছে নিয়ে একটা দল খুলুন। নম্বরে চাপ দিলে কল যাবে।',
            'Pick a district, then a group. Tap a number to call.',
          ),
          style: bangla(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _results(bool bn) {
    final matched = _matched(_scoped());
    final visible = _kind == null
        ? matched
        : [
            for (final item in matched)
              if (_bucket(item.type) == _kind) item,
          ];
    final chips = [
      for (final id in _groupOrder)
        if (_allServices.any((item) => _bucket(item.type) == id)) id,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: chips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final id = chips[index];
              final group = _groupFor(id);
              return _KindChip(
                label: tr(bn, group.bn, group.en),
                selected: _kind == id,
                onTap: () => _selectKind(id),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Text(
            tr(
              bn,
              'মোট ${visible.length} টি জরুরি যোগাযোগ নম্বর উপলব্ধ',
              '${visible.length} emergency numbers',
            ),
            style: bangla(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    tr(bn, 'কোনো তথ্য পাওয়া যায়নি।', 'Nothing found.'),
                    style: bangla(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft,
                    ),
                  ),
                )
              : ListView(
                  padding: shellScrollPadding(
                    context,
                    left: 20,
                    top: 4,
                    right: 20,
                    extraBottom: 12,
                  ),
                  children: _contactChildren(bn, visible),
                ),
        ),
      ],
    );
  }

  List<Widget> _contactChildren(bool bn, List<EmergencyServiceItem> visible) {
    final out = <Widget>[];
    for (final id in _groupOrder) {
      final items = [
        for (final item in visible)
          if (_bucket(item.type) == id) item,
      ];
      if (items.isEmpty) continue;
      if (_kind == null) {
        final group = _groupFor(id);
        out.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: _SectionLabel(tr(bn, group.bn, group.en)),
          ),
        );
      }
      for (final item in items) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ContactCard(
              item: item,
              color: _groupFor(id).color,
              icon: _groupFor(id).icon,
              onCall: () => _callNumber(item.phone),
            ),
          ),
        );
      }
    }
    return out;
  }

  Future<void> _callNumber(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _TopBar extends StatelessWidget {
  final bool bn;

  const _TopBar({required this.bn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: tr(bn, 'ফিরে যান', 'Back'),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          ),
          Expanded(
            child: Text(
              tr(bn, 'জরুরি সহায়তা ডিরেক্টরি', 'Emergency directory'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: bangla(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: bangla(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.muted,
      ),
    );
  }
}

class _DistrictField extends StatelessWidget {
  final bool bn;
  final List<String> districts;
  final String value;
  final ValueChanged<String> onChanged;

  const _DistrictField({
    required this.bn,
    required this.districts,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(
              Icons.expand_more_rounded,
              color: AppColors.inkSoft,
            ),
            style: bangla(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
            items: [
              DropdownMenuItem(
                value: '',
                child: Text(tr(bn, 'সব জেলা', 'All districts')),
              ),
              for (final district in districts)
                DropdownMenuItem(
                  value: district,
                  child: Text(district, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final bool bn;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.bn, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: bangla(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      decoration: InputDecoration(
        hintText: tr(
          bn,
          'থানা, হাসপাতাল বা ফোন নম্বর খুঁজুন...',
          'Search station, hospital, or number...',
        ),
        hintStyle: bangla(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.4),
        ),
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _GroupRow({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF7ED) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFFEA580C)
                  : const Color(0xFFE7E5E4),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bangla(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: bangla(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF7ED) : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFFEA580C)
                  : const Color(0xFFE7E5E4),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Text(
            label,
            style: bangla(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyServiceItem item;
  final Color color;
  final IconData icon;
  final VoidCallback onCall;

  const _ContactCard({
    required this.item,
    required this.color,
    required this.icon,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final place = [
      item.district,
      item.location,
    ].where((part) => part.trim().isNotEmpty).join(' • ');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onCall,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7E5E4)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shownName(item.name),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: bangla(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.25,
                      ),
                    ),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bangla(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      item.phone,
                      style: bangla(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryAmber,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFBBF24),
                      Color(0xFFF59E0B),
                      Color(0xFFEA580C),
                    ],
                  ),
                ),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(
                    Icons.call_rounded,
                    color: Colors.white,
                    size: 26,
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
