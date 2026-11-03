import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
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

  /// Lower-cased name, location and type, built once so search does not
  /// lower-case 900 rows on every keystroke.
  final String searchKey;

  const EmergencyServiceItem({
    required this.id,
    required this.name,
    required this.type,
    required this.district,
    required this.location,
    required this.phone,
    this.address,
    this.searchKey = '',
  });

  factory EmergencyServiceItem.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    final type = json['type']?.toString() ?? 'emergency';
    final location = json['location']?.toString() ?? '';
    return EmergencyServiceItem(
      id: json['id']?.toString() ?? '',
      name: name,
      type: type,
      district: json['district']?.toString() ?? '',
      location: location,
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString(),
      // \u0000 keeps a query from matching across two fields.
      searchKey: '${name.toLowerCase()}\u0000${location.toLowerCase()}\u0000${type.toLowerCase()}',
    );
  }
}

class EmergencyDirectory {
  final List<EmergencyServiceItem> items;
  final List<String> districts;

  const EmergencyDirectory(this.items, this.districts);
}

/// Top-level so it can run in a background isolate.
EmergencyDirectory parseEmergencyDirectory(String raw) {
  final jsonList = jsonDecode(raw) as List<dynamic>;
  final items = jsonList.map((e) => EmergencyServiceItem.fromJson(e as Map<String, dynamic>)).toList();
  final districtSet = <String>{};
  for (final item in items) {
    if (item.district.trim().isNotEmpty) districtSet.add(item.district.trim());
  }
  return EmergencyDirectory(items, districtSet.toList()..sort());
}

Future<EmergencyDirectory>? _directoryCache;

/// The 335 KB directory is parsed once per app run, off the UI isolate.
Future<EmergencyDirectory> loadEmergencyDirectory() {
  return _directoryCache ??= () async {
    final raw = await rootBundle.loadString('assets/data/districtEmergencyServices.json', cache: false);
    return compute(parseEmergencyDirectory, raw, debugLabel: 'emergency-directory');
  }()
      .catchError((Object e) {
    _directoryCache = null;
    throw e;
  });
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
  _Group('ambulance', 'অ্যাম্বুলেন্স', 'Ambulance', Icons.airport_shuttle_rounded, SlmColors.emerald400),
  _Group('fire', 'ফায়ার', 'Fire', Icons.local_fire_department_rounded, SlmColors.danger),
  _Group('police', 'পুলিশ', 'Police', Icons.local_police_rounded, Color(0xFF5B9BF8)),
  _Group('power', 'বিদ্যুৎ', 'Power', Icons.electric_bolt_rounded, Color(0xFFE4C77F)),
];

const _hospitals = _Group('hospitals', 'হাসপাতাল', 'Hospitals', Icons.local_hospital_rounded, Color(0xFF6EE7B7));
const _other = _Group('other', 'অন্যান্য', 'Other', Icons.forum_rounded, Color(0xFF8A97B1));

const _groupOrder = ['ambulance', 'fire', 'police', 'power', 'hospitals', 'other'];

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

String _shownName(String raw) => raw.replaceAll('&#038;', '&').replaceAll('&amp;', '&');

class EmergencyDirectoryScreen extends ConsumerStatefulWidget {
  const EmergencyDirectoryScreen({super.key});

  @override
  ConsumerState<EmergencyDirectoryScreen> createState() => _EmergencyDirectoryScreenState();
}

class _EmergencyDirectoryScreenState extends ConsumerState<EmergencyDirectoryScreen> {
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
      final directory = await loadEmergencyDirectory();
      if (!mounted) return;
      setState(() {
        _allServices = directory.items;
        _districts = directory.districts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<EmergencyServiceItem> _scoped() {
    if (_selectedDistrict.isEmpty) return _allServices;
    return [for (final item in _allServices) if (item.district == _selectedDistrict) item];
  }

  List<EmergencyServiceItem> _matched(List<EmergencyServiceItem> source) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return source;
    return [
      for (final item in source)
        if (item.searchKey.contains(q) || item.phone.contains(q))
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

  Future<void> _callNumber(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);

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
                        SlmTopBar(
                          title: tr(bn, 'জরুরি নম্বর', 'Emergency'),
                          onBack: () => Navigator.of(context).maybePop(),
                          backLabel: tr(bn, 'ফিরে যান', 'Back'),
                        ),
                        if (_isLoading)
                          const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: SlmColors.gold300),
                            ),
                          )
                        else ...[
                          Padding(
                            padding: EdgeInsets.fromLTRB(g, 0, g, 0),
                            child: Column(
                              children: [
                                _DistrictField(
                                  bn: bn,
                                  districts: _districts,
                                  value: _selectedDistrict,
                                  onChanged: (value) => setState(() => _selectedDistrict = value),
                                ),
                                const SizedBox(height: 8),
                                _SearchField(
                                  bn: bn,
                                  onChanged: (value) => setState(() => _searchQuery = value),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(child: _showPicker ? _picker(bn, g) : _results(bn, g)),
                        ],
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

  Widget _picker(bool bn, double g) {
    final otherCount = _count(_other.id);
    return ListView(
      padding: shellScrollPadding(context, left: g, top: 0, right: g, extraBottom: 12),
      children: [
        SlmText(tr(bn, 'এখনই কল', 'Call now'), role: SlmTextRole.label, color: SlmColors.gold300),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.55,
          children: [
            for (final group in _immediate)
              _GroupTile(
                label: tr(bn, group.bn, group.en),
                count: _count(group.id),
                icon: group.icon,
                color: group.color,
                bn: bn,
                onTap: () => _selectKind(group.id),
              ),
          ],
        ),
        const SizedBox(height: 14),
        SlmText(tr(bn, 'অন্যান্য', 'Other'), role: SlmTextRole.label, color: SlmColors.gold300),
        const SizedBox(height: 8),
        _GroupTile(
          label: tr(bn, _hospitals.bn, _hospitals.en),
          count: _count(_hospitals.id),
          icon: _hospitals.icon,
          color: _hospitals.color,
          bn: bn,
          onTap: () => _selectKind(_hospitals.id),
        ),
        if (otherCount > 0) ...[
          const SizedBox(height: 8),
          _GroupTile(
            label: tr(bn, _other.bn, _other.en),
            count: otherCount,
            icon: _other.icon,
            color: _other.color,
            bn: bn,
            onTap: () => _selectKind(_other.id),
          ),
        ],
        const SizedBox(height: 12),
        SlmText(
          tr(
            bn,
            'জেলা বেছে নিন, তারপর একটি দল খুলুন। নম্বরে চাপ দিলে কল যাবে।',
            'Pick a district, then a group. Tap a number to call.',
          ),
          role: SlmTextRole.caption,
          color: SlmColors.mist,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _results(bool bn, double g) {
    final matched = _matched(_scoped());
    final visible = _kind == null
        ? matched
        : [for (final item in matched) if (_bucket(item.type) == _kind) item];
    final chips = [
      for (final id in _groupOrder)
        if (_allServices.any((item) => _bucket(item.type) == id)) id,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: g),
            itemCount: chips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final id = chips[index];
              final group = _groupFor(id);
              return Theme(
                data: Theme.of(context),
                child: SlmChip(
                  label: tr(bn, group.bn, group.en),
                  selected: _kind == id,
                  onTap: () => _selectKind(id),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(g, 10, g, 6),
          child: SlmText(
            tr(bn, '${visible.length} টি নম্বর', '${visible.length} numbers'),
            role: SlmTextRole.caption,
            color: SlmColors.mist,
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: SlmEmptyState(
                    icon: Icons.search_off_rounded,
                    title: tr(bn, 'কোনো তথ্য পাওয়া যায়নি।', 'Nothing found.'),
                  ),
                )
              : ListView(
                  padding: shellScrollPadding(context, left: g, top: 0, right: g, extraBottom: 12),
                  children: _contactChildren(bn, visible),
                ),
        ),
      ],
    );
  }

  List<Widget> _contactChildren(bool bn, List<EmergencyServiceItem> visible) {
    final out = <Widget>[];
    for (final id in _groupOrder) {
      final items = [for (final item in visible) if (_bucket(item.type) == id) item];
      if (items.isEmpty) continue;
      if (_kind == null) {
        final group = _groupFor(id);
        out.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: SlmText(tr(bn, group.bn, group.en), role: SlmTextRole.label, color: SlmColors.gold300),
          ),
        );
      }
      for (final item in items) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
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
        gradient: SlmGradients.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: SlmColors.navy800,
            iconEnabledColor: SlmColors.gold300,
            style: bangla(fontSize: 15, fontWeight: FontWeight.w700, color: SlmColors.ivory),
            items: [
              DropdownMenuItem(value: '', child: Text(tr(bn, 'সব জেলা', 'All districts'))),
              for (final district in districts)
                DropdownMenuItem(value: district, child: Text(district, overflow: TextOverflow.ellipsis)),
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
      cursorColor: SlmColors.gold400,
      style: bangla(fontSize: 15, fontWeight: FontWeight.w600, color: SlmColors.ivory),
      decoration: InputDecoration(
        hintText: tr(bn, 'নাম বা নম্বর খুঁজুন', 'Search name or number'),
        hintStyle: bangla(fontSize: 14, fontWeight: FontWeight.w500, color: SlmColors.slate),
        prefixIcon: const Icon(Icons.search_rounded, color: SlmColors.gold300, size: 22),
        filled: true,
        fillColor: SlmColors.navy900,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: SlmColors.gold400.withValues(alpha: 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: SlmColors.gold400.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SlmColors.gold400, width: 1.4),
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool bn;
  final VoidCallback onTap;

  const _GroupTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.bn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          gradient: SlmGradients.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ivory, height: 1.15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(bn, '$count টি', '$count'),
                    style: bangla(fontSize: 12, fontWeight: FontWeight.w600, color: SlmColors.mist),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.85), size: 20),
          ],
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
    final place = [item.district, item.location].where((part) => part.trim().isNotEmpty).join(' • ');
    return SlmPressable(
      onTap: onCall,
      semanticLabel: item.phone,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          gradient: SlmGradients.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _shownName(item.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ivory, height: 1.2),
                  ),
                  if (place.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bangla(fontSize: 12, fontWeight: FontWeight.w500, color: SlmColors.mist),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    item.phone,
                    style: bangla(fontSize: 16, fontWeight: FontWeight.w800, color: SlmColors.gold300, height: 1.1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SlmGradients.gold,
              ),
              child: const Icon(Icons.call_rounded, color: SlmColors.navy950, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
