import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../data/item_repository.dart';
import '../../domain/models/item.dart';

/// Campus landmark representation with 2D campus plane coordinates.
class CampusLandmark {
  final String id;
  final String name;
  final String shortName;
  final String zone;
  final IconData icon;
  final Offset position; // Canvas coordinates (relative to 1000 x 700 canvas)
  final List<String> keywords;

  const CampusLandmark({
    required this.id,
    required this.name,
    required this.shortName,
    required this.zone,
    required this.icon,
    required this.position,
    required this.keywords,
  });
}

/// All major landmark zones on the university campus.
final List<CampusLandmark> kCampusLandmarks = [
  const CampusLandmark(
    id: 'library',
    name: 'Main Central Library',
    shortName: 'Central Library',
    zone: 'Academic Core',
    icon: Icons.local_library_outlined,
    position: Offset(260, 200),
    keywords: ['library', 'quiet zone', 'books', 'reading', '2nd floor', '3rd floor'],
  ),
  const CampusLandmark(
    id: 'food_court',
    name: 'Student Union & Food Court',
    shortName: 'Food Court',
    zone: 'Student Life Hub',
    icon: Icons.restaurant_outlined,
    position: Offset(520, 240),
    keywords: ['food court', 'student union', 'sub', 'dining', 'canteen'],
  ),
  const CampusLandmark(
    id: 'engineering',
    name: 'Engineering Hall & Technology Labs',
    shortName: 'Engineering Hall',
    zone: 'Tech & Engineering',
    icon: Icons.precision_manufacturing_outlined,
    position: Offset(220, 480),
    keywords: ['engineering', 'lab', 'technology', 'tt', 'robotics'],
  ),
  const CampusLandmark(
    id: 'science',
    name: 'Science Innovation Center',
    shortName: 'Science Center',
    zone: 'Physical Sciences',
    icon: Icons.biotech_outlined,
    position: Offset(530, 490),
    keywords: ['science', 'lecture hall', 'lab 204', 'physics', 'chemistry'],
  ),
  const CampusLandmark(
    id: 'business',
    name: 'Business Complex & Auditorium',
    shortName: 'Business Complex',
    zone: 'Management & Arts',
    icon: Icons.business_center_outlined,
    position: Offset(780, 310),
    keywords: ['business', 'auditorium', 'complex', 'management'],
  ),
  const CampusLandmark(
    id: 'gym',
    name: 'Campus Recreation Center & Gym',
    shortName: 'Recreation & Gym',
    zone: 'Athletics & Fitness',
    icon: Icons.fitness_center_outlined,
    position: Offset(780, 530),
    keywords: ['gym', 'recreation', 'sports', 'fitness', 'court', 'pool'],
  ),
  const CampusLandmark(
    id: 'cafeteria',
    name: 'Central Cafeteria Benches',
    shortName: 'Central Cafeteria',
    zone: 'Dining & Common',
    icon: Icons.local_cafe_outlined,
    position: Offset(420, 110),
    keywords: ['cafeteria', 'bench', 'cafe', 'coffee'],
  ),
  const CampusLandmark(
    id: 'hostels',
    name: 'Campus Residence & Hostels',
    shortName: 'Hostels & Dorms',
    zone: 'Residential Living',
    icon: Icons.hotel_outlined,
    position: Offset(780, 120),
    keywords: ['hostel', 'dorm', 'residence', 'block', 'housing'],
  ),
];

/// Full-featured, interactive campus map explorer.
///
/// Features:
/// - Smooth pan and zoom across the university campus
/// - Approximate privacy fuzzed zones (~100m radius circle around landmarks)
/// - Visual markers with 🟢 Found and 🟠 Lost count badges
/// - Interactive tap-to-inspect landmark & item drawer
/// - Quick landmark jump pills
/// - Type and Category filtering
class CampusMapExplorerWidget extends ConsumerStatefulWidget {
  final String? initialSelectedLocation;
  final ItemType? filterType;

  const CampusMapExplorerWidget({
    super.key,
    this.initialSelectedLocation,
    this.filterType,
  });

  @override
  ConsumerState<CampusMapExplorerWidget> createState() => _CampusMapExplorerWidgetState();
}

class _CampusMapExplorerWidgetState extends ConsumerState<CampusMapExplorerWidget>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformController;
  CampusLandmark? _selectedLandmark;
  ItemType? _selectedType;
  late AnimationController _pulseController;

  static const double kMapWidth = 1000.0;
  static const double kMapHeight = 700.0;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _selectedType = widget.filterType;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Initial center on campus or requested location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialSelectedLocation != null) {
        _selectLandmarkByLocation(widget.initialSelectedLocation!);
      } else {
        _centerMap();
      }
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _centerMap() {
    final size = MediaQuery.of(context).size;
    final scale = math.min(size.width / kMapWidth, (size.height - 180) / kMapHeight) * 0.95;
    final tx = (size.width - kMapWidth * scale) / 2;
    final ty = (size.height - 180 - kMapHeight * scale) / 2;

    _transformController.value = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, tx)
      ..setEntry(1, 3, ty);
  }

  void _zoomToLandmark(CampusLandmark landmark) {
    setState(() => _selectedLandmark = landmark);
    final size = MediaQuery.of(context).size;
    const targetScale = 1.35;
    final tx = size.width / 2 - landmark.position.dx * targetScale;
    final ty = (size.height - 240) / 2 - landmark.position.dy * targetScale;

    _transformController.value = Matrix4.identity()
      ..setEntry(0, 0, targetScale)
      ..setEntry(1, 1, targetScale)
      ..setEntry(0, 3, tx)
      ..setEntry(1, 3, ty);
  }

  void _selectLandmarkByLocation(String location) {
    final locLower = location.toLowerCase();
    for (final landmark in kCampusLandmarks) {
      if (landmark.keywords.any((kw) => locLower.contains(kw)) ||
          landmark.name.toLowerCase().contains(locLower) ||
          landmark.shortName.toLowerCase().contains(locLower)) {
        _zoomToLandmark(landmark);
        return;
      }
    }
    _zoomToLandmark(kCampusLandmarks.first);
  }

  CampusLandmark _matchItemToLandmark(Item item) {
    final locLower = item.approximateLocation.toLowerCase();
    for (final landmark in kCampusLandmarks) {
      if (landmark.keywords.any((kw) => locLower.contains(kw))) {
        return landmark;
      }
    }
    return kCampusLandmarks.first; // Default fallback to Central Library
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allItems = ref.watch(itemsStreamProvider).value ?? [];

    // Filter items according to the active type filter
    final filteredItems = allItems.where((item) {
      if (_selectedType != null && item.type != _selectedType) return false;
      return true;
    }).toList();

    // Group items by landmark
    final Map<String, List<Item>> itemsByLandmark = {};
    for (final landmark in kCampusLandmarks) {
      itemsByLandmark[landmark.id] = [];
    }
    for (final item in filteredItems) {
      final landmark = _matchItemToLandmark(item);
      itemsByLandmark[landmark.id]?.add(item);
    }

    final selectedItems = _selectedLandmark != null
        ? itemsByLandmark[_selectedLandmark!.id] ?? []
        : <Item>[];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F6F8),
      body: Stack(
        children: [
          // Interactive Campus Canvas
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.45,
              maxScale: 2.8,
              boundaryMargin: const EdgeInsets.all(400),
              child: SizedBox(
                width: kMapWidth,
                height: kMapHeight,
                child: Stack(
                  children: [
                    // Base Vector Architectural Map
                    CustomPaint(
                      size: const Size(kMapWidth, kMapHeight),
                      painter: _CampusMapBasePainter(
                        isDark: isDark,
                        selectedLandmark: _selectedLandmark,
                        pulseProgress: _pulseController.value,
                      ),
                    ),

                    // Campus Landmark Buildings & Markers
                    ...kCampusLandmarks.map((landmark) {
                      final itemsAtLandmark = itemsByLandmark[landmark.id] ?? [];
                      final lostCount = itemsAtLandmark.where((i) => i.type == ItemType.lost).length;
                      final foundCount = itemsAtLandmark.where((i) => i.type == ItemType.found).length;
                      final isSelected = _selectedLandmark?.id == landmark.id;

                      return Positioned(
                        left: landmark.position.dx - 80,
                        top: landmark.position.dy - 60,
                        child: GestureDetector(
                          onTap: () => _zoomToLandmark(landmark),
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return _buildLandmarkPinNode(
                                context: context,
                                landmark: landmark,
                                lostCount: lostCount,
                                foundCount: foundCount,
                                isSelected: isSelected,
                                isDark: isDark,
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Top Floating Control Bar: Filters & Quick Landmark Jump
          Positioned(
            top: AppSpacing.s,
            left: AppSpacing.m,
            right: AppSpacing.m,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type Filter Bar
                Row(
                  children: [
                    _buildFilterChip(
                      label: 'All Items (${allItems.length})',
                      isSelected: _selectedType == null,
                      onTap: () => setState(() => _selectedType = null),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Lost Only 🟠',
                      isSelected: _selectedType == ItemType.lost,
                      onTap: () => setState(() => _selectedType = ItemType.lost),
                      isDark: isDark,
                      accentColor: AppColors.mutedAmber,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Found Only 🟢',
                      isSelected: _selectedType == ItemType.found,
                      onTap: () => setState(() => _selectedType = ItemType.found),
                      isDark: isDark,
                      accentColor: AppColors.mutedGreen,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Horizontal Landmark Quick Selector
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: kCampusLandmarks.length + 1,
                    separatorBuilder: (_, index) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ActionChip(
                          avatar: const Icon(Icons.explore_outlined, size: 14),
                          label: const Text('Whole Campus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                          onPressed: () {
                            setState(() => _selectedLandmark = null);
                            _centerMap();
                          },
                        );
                      }
                      final lm = kCampusLandmarks[index - 1];
                      final count = (itemsByLandmark[lm.id] ?? []).length;
                      final isSelected = _selectedLandmark?.id == lm.id;

                      return ActionChip(
                        avatar: Icon(lm.icon, size: 14, color: isSelected ? Colors.white : null),
                        label: Text(
                          '${lm.shortName}${count > 0 ? " ($count)" : ""}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        backgroundColor: isSelected
                            ? (isDark ? Colors.white24 : AppColors.charcoal)
                            : (isDark ? AppColors.surfaceDark : Colors.white),
                        onPressed: () => _zoomToLandmark(lm),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Zoom & Reset Floating Action Buttons
          Positioned(
            right: AppSpacing.m,
            bottom: _selectedLandmark != null ? 240 : 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapActionButton(
                  icon: Icons.add,
                  tooltip: 'Zoom In',
                  onPressed: () {
                    final matrix = _transformController.value.clone();
                    matrix.setEntry(0, 0, matrix.entry(0, 0) * 1.25);
                    matrix.setEntry(1, 1, matrix.entry(1, 1) * 1.25);
                    _transformController.value = matrix;
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildMapActionButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom Out',
                  onPressed: () {
                    final matrix = _transformController.value.clone();
                    matrix.setEntry(0, 0, matrix.entry(0, 0) * 0.8);
                    matrix.setEntry(1, 1, matrix.entry(1, 1) * 0.8);
                    _transformController.value = matrix;
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildMapActionButton(
                  icon: Icons.my_location,
                  tooltip: 'Reset Campus View',
                  onPressed: () {
                    setState(() => _selectedLandmark = null);
                    _centerMap();
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Bottom Landmark Inspection Drawer
          if (_selectedLandmark != null)
            Positioned(
              left: AppSpacing.m,
              right: AppSpacing.m,
              bottom: AppSpacing.m,
              child: _buildLandmarkDetailCard(
                landmark: _selectedLandmark!,
                items: selectedItems,
                isDark: isDark,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    Color? accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (accentColor ?? (isDark ? Colors.white : AppColors.charcoal))
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (accentColor != null ? Colors.white : (isDark ? AppColors.charcoal : Colors.white))
                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 18, color: isDark ? Colors.white : AppColors.charcoal),
          ),
        ),
      ),
    );
  }

  Widget _buildLandmarkPinNode({
    required BuildContext context,
    required CampusLandmark landmark,
    required int lostCount,
    required int foundCount,
    required bool isSelected,
    required bool isDark,
  }) {
    final totalItems = lostCount + foundCount;

    return SizedBox(
      width: 160,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Marker Header: Badges & Icon
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Outer Glowing Aura when selected
              if (isSelected)
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mutedGreen.withValues(alpha: 0.25),
                  ),
                ),

              // Main Pin Node Circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.charcoal
                      : (isDark ? const Color(0xFF242831) : Colors.white),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.mutedGreen
                        : (totalItems > 0 ? AppColors.mutedAmber : (isDark ? Colors.white24 : Colors.black12)),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  landmark.icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : (totalItems > 0
                          ? (foundCount > 0 ? AppColors.mutedGreen : AppColors.mutedAmber)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                ),
              ),

              // Item Count Badges
              if (totalItems > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (foundCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.mutedGreen,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                          child: Text(
                            '$foundCount',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      if (lostCount > 0) ...[
                        const SizedBox(width: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.mutedAmber,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                          child: Text(
                            '$lostCount',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Landmark Label Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.charcoal)
                  : (isDark ? const Color(0xFF1E222B) : Colors.white),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              landmark.shortName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? AppColors.charcoal : Colors.white)
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandmarkDetailCard({
    required CampusLandmark landmark,
    required List<Item> items,
    required bool isDark,
  }) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181B22) : Colors.white,
        borderRadius: AppSpacing.borderRadiusLarge,
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              Icon(landmark.icon, size: 20, color: AppColors.mutedGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      landmark.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${landmark.zone} • Privacy Zone (~100m approximate radius)',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _selectedLandmark = null),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.s),

          // Items listing at this landmark
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'No matching reported items at this landmark.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () => context.go('/report'),
                      icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                      label: const Text('Report Lost or Found Item Here', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isLost = item.type == ItemType.lost;

                  return InkWell(
                    onTap: () => context.go('/items/${item.id}'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLost ? AppColors.mutedAmberLight : AppColors.mutedGreenLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isLost ? 'LOST' : 'FOUND',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isLost ? AppColors.mutedAmber : AppColors.mutedGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${item.category.label} • ${item.approximateLocation}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (item.latitude != null && item.longitude != null) ...[
                            IconButton(
                              icon: const Icon(Icons.place, size: 18, color: Color(0xFFEA4335)),
                              tooltip: 'Open in Google Maps (${item.latitude!.toStringAsFixed(4)}°, ${item.longitude!.toStringAsFixed(4)}°)',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}');
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              },
                            ),
                            const SizedBox(width: 4),
                          ],
                          const Icon(Icons.chevron_right, size: 18),
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
}

/// Vector Painter rendering campus ring roads, academic blocks, lawns, and privacy zones.
class _CampusMapBasePainter extends CustomPainter {
  final bool isDark;
  final CampusLandmark? selectedLandmark;
  final double pulseProgress;

  _CampusMapBasePainter({
    required this.isDark,
    required this.selectedLandmark,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = isDark ? const Color(0xFF11141A) : const Color(0xFFF0F3F6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle campus grid lines
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF1A1E26) : const Color(0xFFE2E6EB)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Campus Lawns & Green Zones
    final lawnPaint = Paint()
      ..color = isDark ? const Color(0xFF142419) : const Color(0xFFE3EFE3)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(320, 200, 140, 220), const Radius.circular(20)),
      lawnPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(640, 380, 100, 140), const Radius.circular(16)),
      lawnPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(120, 100, 100, 80), const Radius.circular(16)),
      lawnPaint,
    );

    // Campus Reflection Pond / Lake
    final pondPaint = Paint()
      ..color = isDark ? const Color(0xFF14202C) : const Color(0xFFDCEAF7)
      ..style = PaintingStyle.fill;
    canvas.drawOval(const Rect.fromLTWH(340, 230, 100, 60), pondPaint);

    // Campus Pedestrian Walkways & Connecting Avenues
    final walkPaint = Paint()
      ..color = isDark ? const Color(0xFF262C38) : const Color(0xFFD6DBE2)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    // Avenue connections between landmarks
    canvas.drawLine(const Offset(260, 200), const Offset(520, 240), walkPaint);
    canvas.drawLine(const Offset(520, 240), const Offset(780, 310), walkPaint);
    canvas.drawLine(const Offset(260, 200), const Offset(220, 480), walkPaint);
    canvas.drawLine(const Offset(220, 480), const Offset(530, 490), walkPaint);
    canvas.drawLine(const Offset(530, 490), const Offset(780, 530), walkPaint);
    canvas.drawLine(const Offset(520, 240), const Offset(530, 490), walkPaint);
    canvas.drawLine(const Offset(420, 110), const Offset(520, 240), walkPaint);
    canvas.drawLine(const Offset(780, 120), const Offset(780, 310), walkPaint);

    // Campus Outer Perimeter Ring Road
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF1E222B) : const Color(0xFFC7CED6)
      ..strokeWidth = 14.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(80, 50, 840, 580), const Radius.circular(40)),
      roadPaint,
    );

    // Building Footprints (Architectural silhouettes)
    final buildingPaint = Paint()
      ..color = isDark ? const Color(0xFF1F242E) : const Color(0xFFDDE2E8)
      ..style = PaintingStyle.fill;

    for (final lm in kCampusLandmarks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: lm.position, width: 80, height: 50),
          const Radius.circular(8),
        ),
        buildingPaint,
      );
    }

    // Selected Landmark Approximate Privacy Fuzzed Zone (~100m radius)
    if (selectedLandmark != null) {
      final center = selectedLandmark!.position;
      final radius = 100.0 + (pulseProgress * 10.0);

      final fuzzedZonePaint = Paint()
        ..color = AppColors.mutedGreen.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fuzzedZonePaint);

      final boundaryPaint = Paint()
        ..color = AppColors.mutedGreen.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, boundaryPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CampusMapBasePainter oldDelegate) {
    return oldDelegate.selectedLandmark != selectedLandmark ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.isDark != isDark;
  }
}
