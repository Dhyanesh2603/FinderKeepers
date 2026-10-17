import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// Real Google Map preview embedded in the item detail screen.
///
/// Displays actual Google Maps satellite / street imagery centered at the item's
/// exact or approximate coordinates with a privacy radius and pin marker.
class CampusMapWidget extends StatefulWidget {
  final String locationName;
  final double? latitude;
  final double? longitude;

  const CampusMapWidget({
    super.key,
    required this.locationName,
    this.latitude,
    this.longitude,
  });

  @override
  State<CampusMapWidget> createState() => _CampusMapWidgetState();
}

class _CampusMapWidgetState extends State<CampusMapWidget> {
  late final MapController _mapController;
  bool _isSatellite = true;

  static const double _defaultCampusLat = 12.9692;
  static const double _defaultCampusLng = 79.1559;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng _resolveCoordinates() {
    if (widget.latitude != null && widget.longitude != null) {
      return LatLng(widget.latitude!, widget.longitude!);
    }

    final lower = widget.locationName.toLowerCase();
    if (lower.contains('food') || lower.contains('court') || lower.contains('union')) {
      return const LatLng(12.9680, 79.1580);
    } else if (lower.contains('engineering') || lower.contains('lab 204') || lower.contains('tt')) {
      return const LatLng(12.9710, 79.1594);
    } else if (lower.contains('science') || lower.contains('lecture hall')) {
      return const LatLng(12.9722, 79.1638);
    } else if (lower.contains('business') || lower.contains('auditorium')) {
      return const LatLng(12.9705, 79.1610);
    } else if (lower.contains('gym') || lower.contains('recreation') || lower.contains('sports')) {
      return const LatLng(12.9715, 79.1645);
    } else if (lower.contains('cafeteria') || lower.contains('bench')) {
      return const LatLng(12.9675, 79.1570);
    } else if (lower.contains('hostel') || lower.contains('dorm') || lower.contains('residence')) {
      return const LatLng(12.9730, 79.1650);
    }

    return const LatLng(_defaultCampusLat, _defaultCampusLng);
  }

  String _getTileUrl() {
    return _isSatellite
        ? 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}' // Google Satellite Hybrid
        : 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}'; // Google Street Maps
  }

  Future<void> _openExternalGoogleMaps(LatLng point) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final point = _resolveCoordinates();

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131518) : const Color(0xFFE9ECEF),
        borderRadius: AppSpacing.borderRadiusLarge,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusLarge,
        child: Stack(
          children: [
            // Real Live Google Maps View
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: point,
                initialZoom: 17.2,
                minZoom: 14.0,
                maxZoom: 19.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                // Google Maps Tile Layer with subdomains and OSM fallback
                TileLayer(
                  urlTemplate: _getTileUrl(),
                  subdomains: const ['0', '1', '2', '3'],
                  fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.finderskeepers.finders_keepers',
                  maxZoom: 20,
                ),

                // ~50m Privacy Approximate Location Circle
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: point,
                      radius: 45,
                      useRadiusInMeter: true,
                      color: AppColors.mutedAmber.withValues(alpha: 0.25),
                      borderColor: AppColors.mutedAmber,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),

                // Pin Marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Colors.redAccent,
                            size: 38,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Top Overlay: Live Map Badge & Mode Switcher
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 12, color: Colors.greenAccent),
                        const SizedBox(width: 4),
                        Text(
                          'Approximate (~100m)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Satellite / Street Toggle
                  InkWell(
                    onTap: () => setState(() => _isSatellite = !_isSatellite),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSatellite ? Icons.map_outlined : Icons.satellite_alt_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isSatellite ? 'Street' : 'Satellite',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Full Campus Map Link
                  InkWell(
                    onTap: () => context.go('/map?location=${Uri.encodeComponent(widget.locationName)}'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fullscreen, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Full Map',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Overlay: Location Label & Open Google Maps Button
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87.withValues(alpha: 0.80),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.locationName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _openExternalGoogleMaps(point),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA4335),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_outlined, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Directions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
