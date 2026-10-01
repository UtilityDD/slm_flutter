import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../shell/app_routes.dart';
import '../shell/shell_providers.dart';
import 'library_catalog.dart';

class IdentifyScreen extends ConsumerStatefulWidget {
  const IdentifyScreen({super.key});

  @override
  ConsumerState<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends ConsumerState<IdentifyScreen> {
  String _query = '';
  String _chip = 'All';

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final catalog = ref.watch(libraryCatalogProvider);

    return SlmBackdrop(
      child: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (items) {
          final chips = ['All', ...categoryOrder.where((id) => items.any((item) => item.category == id))];
          final shown = items.where((item) {
            final matchesChip = _chip == 'All' || item.category == _chip;
            final q = _query.trim().toLowerCase();
            final hay = '${item.nameBn} ${item.functionBn} ${item.guideBn}'.toLowerCase();
            return matchesChip && (q.isEmpty || hay.contains(q));
          }).toList();

          return Stack(
            children: [
              SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Text(
                    tr(bn, 'পরিচিতি', 'Identify'),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Text(
                    tr(bn, 'আগে ছবি দেখুন। তারপর কুইজে নাম ধরুন।', 'Look first. Then name them in the quiz.'),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: tr(bn, 'নাম খুঁজুন', 'Search by name'),
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: const Color(0xE6FFFFFF),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0x61D6BDA4))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0x61D6BDA4))),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: chips.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final id = chips[index];
                      final selected = _chip == id;
                      final label = id == 'All' ? tr(bn, 'সব', 'All') : categoryLabel(id, bn);
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => setState(() => _chip = id),
                        selectedColor: const Color(0xFFCCFBF1),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: selected ? const Color(0xFF0F766E) : AppColors.inkSoft,
                        ),
                        side: BorderSide(color: selected ? const Color(0xFF5EEAD4) : const Color(0x61D6BDA4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: shown.length,
                    itemBuilder: (context, index) {
                      final item = shown[index];
                      return _PhotoCard(
                        item: item,
                        bn: bn,
                        onTap: () => _openDetail(context, bn, item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: SafeArea(
                  top: false,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.identifyPlay),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      tr(bn, 'ছবি দেখে চিনুন', 'Name the photos'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, bool bn, LibraryItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFEFB),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.86;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE7D5C6), borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 14),
                if (item.hasPhoto)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: Image.asset(item.images.first, fit: BoxFit.cover),
                    ),
                  )
                else
                  Container(
                    height: 120,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(categoryLabel(item.category, bn), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                const SizedBox(height: 14),
                Text(categoryLabel(item.category, bn), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F766E))),
                const SizedBox(height: 4),
                Text(item.nameBn, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.25, color: AppColors.ink)),
                if (item.functionBn.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(item.functionBn, style: const TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                ],
                if (item.guideBn.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(item.guideBn, style: const TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w700, color: Color(0xFF9A3412))),
                  ),
                ],
            ],
          ),
        ),
        );
      },
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final LibraryItem item;
  final bool bn;
  final VoidCallback onTap;

  const _PhotoCard({required this.item, required this.bn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFEFB),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x61D6BDA4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                  child: item.hasPhoto
                      ? Image.asset(
                          item.images.first,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => const ColoredBox(
                            color: Color(0xFFF5F5F4),
                            child: Icon(Icons.image_outlined),
                          ),
                        )
                      : ColoredBox(
                          color: const Color(0xFFF5F5F4),
                          child: Center(
                            child: Text(
                              categoryLabel(item.category, bn),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted),
                            ),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Text(
                  item.nameBn,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, height: 1.25, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
