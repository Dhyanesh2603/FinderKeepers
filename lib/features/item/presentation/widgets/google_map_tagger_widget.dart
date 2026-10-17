import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

/// Result returned when a user tags a location on Google Map.
class TaggedLocationResult {
  final double latitude;
  final double longitude;
  final String locationName;
  final String description;

  const TaggedLocationResult({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.description,
  });
}

/// Campus landmark reference with real GPS coordinates.
class CampusGeoPoint {
  final String name;
  final String shortName;
  final double latitude;
  final double longitude;
  final Offset canvasPosition;

  const CampusGeoPoint({
    required this.name,
    required this.shortName,
    required this.latitude,
    required this.longitude,
    this.canvasPosition = Offset.zero,
  });
}

final List<CampusGeoPoint> kCampusGeoPresets = [
  const CampusGeoPoint(
    name: 'Main Central Library',
    shortName: 'Central Library',
    latitude: 12.9692,
    longitude: 79.1559,
    canvasPosition: Offset(260, 200),
  ),
  const CampusGeoPoint(
    name: 'Student Union Building • Food Court',
    shortName: 'Food Court',
    latitude: 12.9680,
    longitude: 79.1580,
    canvasPosition: Offset(520, 240),
  ),
  const CampusGeoPoint(
    name: 'Engineering Hall • Technology Labs',
    shortName: 'Engineering Hall',
    latitude: 12.9710,
    longitude: 79.1594,
    canvasPosition: Offset(220, 480),
  ),
  const CampusGeoPoint(
    name: 'Science Innovation Center',
    shortName: 'Science Center',
    latitude: 12.9722,
    longitude: 79.1638,
    canvasPosition: Offset(530, 490),
  ),
  const CampusGeoPoint(
    name: 'Business Complex & Auditorium',
    shortName: 'Business Complex',
    latitude: 12.9705,
    longitude: 79.1610,
    canvasPosition: Offset(780, 310),
  ),
  const CampusGeoPoint(
    name: 'Campus Recreation Center & Gym',
    shortName: 'Recreation & Gym',
    latitude: 12.9715,
    longitude: 79.1645,
    canvasPosition: Offset(780, 530),
  ),
  const CampusGeoPoint(
    name: 'Central Cafeteria Bench',
    shortName: 'Central Cafeteria',
    latitude: 12.9675,
    longitude: 79.1570,
    canvasPosition: Offset(420, 110),
  ),
  const CampusGeoPoint(
    name: 'Campus Residence & Hostels',
    shortName: 'Hostels & Dorms',
    latitude: 12.9730,
    longitude: 79.1650,
    canvasPosition: Offset(780, 120),
  ),
];

enum GoogleMapStyle { street, satellite, hybrid }

/// Interactive Google Map Pin Dropper & Location Tagger.
///
/// Loads real Google Maps satellite & street tile imagery, allowing users to
/// pan, zoom, and pinpoint the exact physical location of a lost or found item.
class GoogleMapTaggerWidget extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialLocationName;

  const GoogleMapTaggerWidget({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialLocationName,
  });

  @override
  State<GoogleMapTaggerWidget> createState() => _GoogleMapTaggerWidgetState();
}

class _GoogleMapTaggerWidgetState extends State<GoogleMapTaggerWidget> {
  late final MapController _mapController;
  late double _selectedLat;
  late double _selectedLng;
  late String _selectedLocationName;
  GoogleMapStyle _mapStyle = GoogleMapStyle.hybrid;

  static const double _defaultCampusLat = 12.9692;
  static const double _defaultCampusLng = 79.1559;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLat = widget.initialLat ?? _defaultCampusLat;
    _selectedLng = widget.initialLng ?? _defaultCampusLng;
    _selectedLocationName = widget.initialLocationName ?? 'Main Central Library';
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  String _getTileUrl() {
    switch (_mapStyle) {
      case GoogleMapStyle.hybrid:
        // Real Google Maps Satellite + Road & Campus Labels
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case GoogleMapStyle.satellite:
        // Real Google Maps High-Res Satellite Imagery
        return 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
      case GoogleMapStyle.street:
        // Real Google Maps Road & Campus Vector Streets
        return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLat = point.latitude;
      _selectedLng = point.longitude;

      // Find closest campus landmark or format custom pin
      CampusGeoPoint? closest;
      double minDistance = double.infinity;

      for (final preset in kCampusGeoPresets) {
        final dLat = preset.latitude - point.latitude;
        final dLng = preset.longitude - point.longitude;
        final dist = (dLat * dLat) + (dLng * dLng);
        if (dist < minDistance) {
          minDistance = dist;
          closest = preset;
        }
      }

      // If within ~150 meters, snap label to landmark with precision note
      if (closest != null && minDistance < 0.00002) {
        _selectedLocationName = closest.name;
      } else {
        _selectedLocationName =
            'Campus Location (${point.latitude.toStringAsFixed(4)}° N, ${point.longitude.toStringAsFixed(4)}° E)';
      }
    });
  }

  void _selectPreset(CampusGeoPoint preset) {
    setState(() {
      _selectedLat = preset.latitude;
      _selectedLng = preset.longitude;
      _selectedLocationName = preset.name;
    });
    _mapController.move(LatLng(preset.latitude, preset.longitude), 17.5);
  }

  void _confirmSelection() {
    final result = TaggedLocationResult(
      latitude: _selectedLat,
      longitude: _selectedLng,
      locationName: _selectedLocationName,
      description:
          'Exact GPS: ${_selectedLat.toStringAsFixed(6)}° N, ${_selectedLng.toStringAsFixed(6)}° E',
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.s, AppSpacing.xs),
            child: Row(
              children: [
                const Icon(Icons.pin_drop_rounded, color: Colors.redAccent, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Google Maps Location Tagger',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Tap anywhere on the live Google Map to pinpoint the exact spot',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Map Style Switcher & Center button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: 4),
            child: Row(
              children: [
                _buildStylePill('Satellite', GoogleMapStyle.hybrid, Icons.satellite_alt_rounded),
                const SizedBox(width: 6),
                _buildStylePill('Street', GoogleMapStyle.street, Icons.map_outlined),
                const Spacer(),
                IconButton.filledTonal(
                  icon: const Icon(Icons.my_location, size: 18),
                  tooltip: 'Reset to Campus Center',
                  onPressed: () {
                    _mapController.move(const LatLng(_defaultCampusLat, _defaultCampusLng), 16.5);
                  },
                ),
              ],
            ),
          ),

          // Quick Campus Landmark Jump Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              itemCount: kCampusGeoPresets.length,
              separatorBuilder: (_, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final preset = kCampusGeoPresets[index];
                final isSelected = (_selectedLat - preset.latitude).abs() < 0.0005 &&
                    (_selectedLng - preset.longitude).abs() < 0.0005;

                return ChoiceChip(
                  label: Text(preset.shortName, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  selectedColor: AppColors.mutedGreenLight,
                  onSelected: (_) => _selectPreset(preset),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Live Interactive Google Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_selectedLat, _selectedLng),
                    initialZoom: 17.0,
                    minZoom: 14.0,
                    maxZoom: 19.5,
                    onTap: _onMapTapped,
                  ),
                  children: [
                    // Real Google Maps Tile Layer
                    TileLayer(
                      urlTemplate: _getTileUrl(),
                      userAgentPackageName: 'com.finderskeepers.finders_keepers',
                      maxZoom: 20,
                    ),

                    // ~80m Privacy / Landmark Circle around selected point
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: LatLng(_selectedLat, _selectedLng),
                          radius: 40,
                          useRadiusInMeter: true,
                          color: AppColors.mutedGreen.withValues(alpha: 0.20),
                          borderColor: AppColors.mutedGreen,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),

                    // Pin Marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_selectedLat, _selectedLng),
                          width: 60,
                          height: 60,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Exact Location',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Icon(
                                Icons.location_on_rounded,
                                color: Colors.redAccent,
                                size: 36,
                                shadows: [
                                  Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Floating Live Coordinate Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.gps_fixed, size: 13, color: Colors.greenAccent),
                        const SizedBox(width: 6),
                        Text(
                          '${_selectedLat.toStringAsFixed(5)}° N, ${_selectedLng.toStringAsFixed(5)}° E',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Map Zoom Controls
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'map_zoom_in',
                        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(LatLng(_selectedLat, _selectedLng), currentZoom + 1);
                        },
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 6),
                      FloatingActionButton.small(
                        heroTag: 'map_zoom_out',
                        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(LatLng(_selectedLat, _selectedLng), currentZoom - 1);
                        },
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Confirmation Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.mutedGreen, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedLocationName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tagged GPS: ${_selectedLat.toStringAsFixed(6)}° N, ${_selectedLng.toStringAsFixed(6)}° E',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  AppButton(
                    label: 'Pinpoint & Tag This Exact Location',
                    onPressed: _confirmSelection,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylePill(String title, GoogleMapStyle style, IconData icon) {
    final isSelected = _mapStyle == style;
    return InkWell(
      onTap: () => setState(() => _mapStyle = style),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.charcoal : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.charcoal : Colors.grey.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
