import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../data/item_repository.dart';
import '../../domain/models/item.dart';

/// Campus landmark representation with real GPS coordinates.
class CampusLandmark {
  final String id;
  final String name;
  final String shortName;
  final String zone;
  final IconData icon;
  final double latitude;
  final double longitude;
  final List<String> keywords;

  const CampusLandmark({
    required this.id,
    required this.name,
    required this.shortName,
    required this.zone,
    required this.icon,
    required this.latitude,
    required this.longitude,
    required this.keywords,
  });
}

/// Standardized campus landmark zones with real GPS coordinates.
final List<CampusLandmark> kCampusLandmarks = [
  const CampusLandmark(
    id: 'library',
    name: 'Main Central Library',
    shortName: 'Library',
    zone: 'Academic Core',
    icon: Icons.local_library_outlined,
    latitude: 12.9692,
    longitude: 79.1559,
    keywords: ['library', 'quiet zone', 'books', 'reading', '2nd floor', '3rd floor'],
  ),
  const CampusLandmark(
    id: 'food_court',
    name: 'Student Union & Food Court',
    shortName: 'Food Court',
    zone: 'Student Life Hub',
    icon: Icons.restaurant_outlined,
    latitude: 12.9680,
    longitude: 79.1580,
    keywords: ['food court', 'student union', 'sub', 'dining', 'canteen'],
  ),
  const CampusLandmark(
    id: 'engineering',
    name: 'Engineering Hall & Technology Labs',
    shortName: 'Engineering',
    zone: 'Tech & Engineering',
    icon: Icons.precision_manufacturing_outlined,
    latitude: 12.9710,
    longitude: 79.1594,
    keywords: ['engineering', 'lab', 'technology', 'tt', 'robotics'],
  ),
  const CampusLandmark(
    id: 'science',
    name: 'Science Innovation Center',
    shortName: 'Science Center',
    zone: 'Physical Sciences',
    icon: Icons.biotech_outlined,
    latitude: 12.9722,
    longitude: 79.1638,
    keywords: ['science', 'lecture hall', 'lab 204', 'physics', 'chemistry'],
  ),
  const CampusLandmark(
    id: 'business',
    name: 'Business Complex & Auditorium',
    shortName: 'Business',
    zone: 'Management & Arts',
    icon: Icons.business_center_outlined,
    latitude: 12.9705,
    longitude: 79.1610,
    keywords: ['business', 'auditorium', 'complex', 'management'],
  ),
  const CampusLandmark(
    id: 'gym',
    name: 'Campus Recreation Center & Gym',
    shortName: 'Gym & Sports',
    zone: 'Athletics & Fitness',
    icon: Icons.fitness_center_outlined,
    latitude: 12.9715,
    longitude: 79.1645,
    keywords: ['gym', 'recreation', 'sports', 'fitness', 'court', 'pool'],
  ),
  const CampusLandmark(
    id: 'cafeteria',
    name: 'Central Cafeteria Benches',
    shortName: 'Cafeteria',
    zone: 'Dining & Common',
    icon: Icons.local_cafe_outlined,
    latitude: 12.9675,
    longitude: 79.1570,
    keywords: ['cafeteria', 'bench', 'cafe', 'coffee'],
  ),
  const CampusLandmark(
    id: 'hostels',
    name: 'Campus Residence & Hostels',
    shortName: 'Hostels',
    zone: 'Residential Living',
    icon: Icons.hotel_outlined,
    latitude: 12.9730,
    longitude: 79.1650,
    keywords: ['hostel', 'dorm', 'residence', 'room'],
  ),
];

enum CampusMapFilter { all, foundOnly, lostOnly }

/// Real Interactive Google Map Explorer for Campus Lost & Found.
class CampusMapExplorer extends ConsumerStatefulWidget {
  final String? initialLocation;
  final String? initialSelectedLocation;
  final ItemType? filterType;

  const CampusMapExplorer({
    super.key,
    this.initialLocation,
    this.initialSelectedLocation,
    this.filterType,
  });

  @override
  ConsumerState<CampusMapExplorer> createState() => _CampusMapExplorerState();
}

class _CampusMapExplorerState extends ConsumerState<CampusMapExplorer> {
  late final MapController _mapController;
  CampusMapFilter _filter = CampusMapFilter.all;
  bool _isSatellite = true;
  Item? _selectedItem;

  static const double _campusCenterLat = 12.9702;
  static const double _campusCenterLng = 79.1595;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.filterType == ItemType.found) {
      _filter = CampusMapFilter.foundOnly;
    } else if (widget.filterType == ItemType.lost) {
      _filter = CampusMapFilter.lostOnly;
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  String _getTileUrl() {
    return _isSatellite
        ? 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}' // Google Satellite Hybrid
        : 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}'; // Google Street Maps
  }

  LatLng _getItemCoordinates(Item item) {
    if (item.latitude != null && item.longitude != null) {
      return LatLng(item.latitude!, item.longitude!);
    }
    // Fallback: match approximate location string to landmark preset
    final lower = item.approximateLocation.toLowerCase();
    for (final landmark in kCampusLandmarks) {
      if (lower.contains(landmark.shortName.toLowerCase()) ||
          lower.contains(landmark.name.toLowerCase())) {
        return LatLng(landmark.latitude, landmark.longitude);
      }
    }
    return const LatLng(_campusCenterLat, _campusCenterLng);
  }

  Future<void> _openExternalDirections(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(itemsStreamProvider).value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredItems = allItems.where((item) {
      if (_filter == CampusMapFilter.foundOnly && item.type != ItemType.found) {
        return false;
      }
      if (_filter == CampusMapFilter.lostOnly && item.type != ItemType.lost) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Controls Header: Filter Chips & Map Mode Switcher
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 8),
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          child: Row(
            children: [
              _buildFilterChip('All (${allItems.length})', CampusMapFilter.all),
              const SizedBox(width: 6),
              _buildFilterChip('🟢 Found', CampusMapFilter.foundOnly),
              const SizedBox(width: 6),
              _buildFilterChip('🟠 Lost', CampusMapFilter.lostOnly),
              const Spacer(),
              // Satellite vs Street Toggle
              IconButton(
                icon: Icon(_isSatellite ? Icons.map_outlined : Icons.satellite_alt_rounded),
                tooltip: _isSatellite ? 'Switch to Street Map' : 'Switch to Satellite',
                onPressed: () => setState(() => _isSatellite = !_isSatellite),
              ),
              IconButton(
                icon: const Icon(Icons.my_location),
                tooltip: 'Reset Campus View',
                onPressed: () {
                  _mapController.move(
                    const LatLng(_campusCenterLat, _campusCenterLng),
                    16.2,
                  );
                },
              ),
            ],
          ),
        ),

        // Live Interactive Google Map
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(_campusCenterLat, _campusCenterLng),
                  initialZoom: 16.2,
                  minZoom: 14.0,
                  maxZoom: 19.5,
                ),
                children: [
                  // Google Maps Live Tile Layer with subdomains and OSM fallback
                  TileLayer(
                    urlTemplate: _getTileUrl(),
                    subdomains: const ['0', '1', '2', '3'],
                    fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.finderskeepers.finders_keepers',
                    maxZoom: 20,
                  ),

                  // Privacy Fuzz Circles (~100m approximate radius)
                  CircleLayer(
                    circles: filteredItems.map((item) {
                      final coords = _getItemCoordinates(item);
                      final isFound = item.type == ItemType.found;
                      final isSelected = _selectedItem?.id == item.id;

                      return CircleMarker(
                        point: coords,
                        radius: isSelected ? 50 : 35,
                        useRadiusInMeter: true,
                        color: (isFound ? AppColors.mutedGreen : AppColors.mutedAmber)
                            .withValues(alpha: isSelected ? 0.35 : 0.18),
                        borderColor: isFound ? AppColors.mutedGreen : AppColors.mutedAmber,
                        borderStrokeWidth: isSelected ? 2.5 : 1.2,
                      );
                    }).toList(),
                  ),

                  // Plotted Item Markers
                  MarkerLayer(
                    markers: filteredItems.map((item) {
                      final coords = _getItemCoordinates(item);
                      final isFound = item.type == ItemType.found;
                      final isSelected = _selectedItem?.id == item.id;

                      return Marker(
                        point: coords,
                        width: isSelected ? 55 : 44,
                        height: isSelected ? 55 : 44,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedItem = item);
                            _mapController.move(coords, 17.5);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFound ? AppColors.mutedGreen : AppColors.mutedAmber,
                              border: Border.all(
                                color: Colors.white,
                                width: isSelected ? 3.0 : 2.0,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFound ? Icons.check_circle_outline : Icons.search_rounded,
                              color: Colors.white,
                              size: isSelected ? 28 : 22,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Map Legend
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 10, color: AppColors.mutedGreen),
                      SizedBox(width: 4),
                      Text('Found', style: TextStyle(color: Colors.white, fontSize: 11)),
                      SizedBox(width: 10),
                      Icon(Icons.circle, size: 10, color: AppColors.mutedAmber),
                      SizedBox(width: 4),
                      Text('Lost', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ),

              // Selected Item Bottom Card Preview
              if (_selectedItem != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _buildItemPreviewCard(_selectedItem!, isDark),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, CampusMapFilter filter) {
    final isSelected = _filter == filter;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.mutedGreen,
      backgroundColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFE5E7EB),
      showCheckmark: false,
      onSelected: (_) => setState(() => _filter = filter),
    );
  }

  Widget _buildItemPreviewCard(Item item, bool isDark) {
    final isFound = item.type == ItemType.found;
    final coords = _getItemCoordinates(item);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isFound ? AppColors.mutedGreenLight : AppColors.mutedAmberLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(
                    isFound ? 'FOUND ITEM' : 'LOST ITEM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isFound ? AppColors.mutedGreen : AppColors.mutedAmber,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _selectedItem = null),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.mutedBlue),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.approximateLocation,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                    icon: const Icon(Icons.directions_outlined, size: 16),
                    label: const Text('Directions', style: TextStyle(fontSize: 12)),
                    onPressed: () => _openExternalDirections(coords.latitude, coords.longitude),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFound ? AppColors.mutedGreen : AppColors.mutedAmber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View Details', style: TextStyle(fontSize: 12)),
                    onPressed: () => context.go('/items/${item.id}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compatibility alias for CampusMapExplorer.
typedef CampusMapExplorerWidget = CampusMapExplorer;
