import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../shell/shell_insets.dart';

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

class EmergencyDirectoryScreen extends StatefulWidget {
  const EmergencyDirectoryScreen({super.key});

  @override
  State<EmergencyDirectoryScreen> createState() => _EmergencyDirectoryScreenState();
}

class _EmergencyDirectoryScreenState extends State<EmergencyDirectoryScreen> {
  List<EmergencyServiceItem> _allServices = [];
  List<EmergencyServiceItem> _filteredServices = [];
  List<String> _districts = ['সব জেলা (All)'];
  String _selectedDistrict = 'সব জেলা (All)';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmergencyData();
  }

  Future<void> _loadEmergencyData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/districtEmergencyServices.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final items = jsonList.map((e) => EmergencyServiceItem.fromJson(e)).toList();

      final districtSet = <String>{};
      for (final item in items) {
        if (item.district.trim().isNotEmpty) {
          districtSet.add(item.district.trim());
        }
      }
      final sortedDistricts = districtSet.toList()..sort();

      setState(() {
        _allServices = items;
        _districts = ['সব জেলা (All)', ...sortedDistricts];
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    List<EmergencyServiceItem> list = _allServices;

    if (_selectedDistrict != 'সব জেলা (All)') {
      list = list.where((item) => item.district == _selectedDistrict).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((item) {
        return item.name.toLowerCase().contains(q) ||
            item.phone.contains(q) ||
            item.location.toLowerCase().contains(q) ||
            item.type.toLowerCase().contains(q);
      }).toList();
    }

    setState(() {
      _filteredServices = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('জরুরি সহায়তা ডিরেক্টরি'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Search and District Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: isDark ? AppColors.slate900 : AppColors.slate50,
                  child: Column(
                    children: [
                      // Search TextField
                      TextField(
                        onChanged: (val) {
                          _searchQuery = val;
                          _applyFilter();
                        },
                        decoration: InputDecoration(
                          hintText: 'থানা, হাসপাতাল বা ফোন নম্বর খুঁজুন...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: isDark ? AppColors.slate800 : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.slate700 : AppColors.slate200,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // District Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.slate800 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.slate700 : AppColors.slate200,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDistrict,
                            isExpanded: true,
                            items: _districts.map((d) {
                              return DropdownMenuItem(
                                value: d,
                                child: Text(d, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                _selectedDistrict = val;
                                _applyFilter();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Count Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        'মোট ${_filteredServices.length} টি জরুরি যোগাযোগ নম্বর উপলব্ধ',
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                // Service List
                Expanded(
                  child: _filteredServices.isEmpty
                      ? const Center(child: Text('কোনো তথ্য পাওয়া যায়নি।'))
                      : ListView.builder(
                          padding: shellScrollPadding(context, left: 16, top: 8, right: 16, extraBottom: 8),
                          itemCount: _filteredServices.length,
                          itemBuilder: (context, index) {
                            final item = _filteredServices[index];
                            return _buildServiceCard(item, isDark);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildServiceCard(EmergencyServiceItem item, bool isDark) {
    IconData iconData = Icons.local_police_rounded;
    Color iconColor = AppColors.electricBlue;

    if (item.type.toLowerCase().contains('hospital') || item.type.toLowerCase().contains('health')) {
      iconData = Icons.local_hospital_rounded;
      iconColor = AppColors.safeGreen;
    } else if (item.type.toLowerCase().contains('fire')) {
      iconData = Icons.local_fire_department_rounded;
      iconColor = AppColors.safetyOrange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.slate700 : AppColors.slate200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.district} • ${item.location}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  item.phone,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.primaryAmber,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: () => _callNumber(item.phone),
            icon: const Icon(Icons.call_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.safeGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _callNumber(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
