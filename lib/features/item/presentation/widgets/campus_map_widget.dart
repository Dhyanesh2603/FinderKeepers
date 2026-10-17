import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// Interactive vector map of campus with approximate privacy fuzzed circle.
class CampusMapWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 220,
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
            // Custom vector campus grid & paths
            CustomPaint(
              size: const Size(double.infinity, 220),
              painter: _CampusGridPainter(isDark: isDark),
            ),

            // Approximate Fuzzed Radius Circle & Pulse
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mutedAmber.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.mutedAmber.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.mutedAmber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mutedAmber.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      locationName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Top Privacy Pill Indicator
            Positioned(
              top: AppSpacing.s,
              left: AppSpacing.s,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 13, color: AppColors.mutedGreen),
                    SizedBox(width: 4),
                    Text(
                      'Privacy Fuzzed Zone (~100m)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            // Top Right: Open in Campus Map Explorer
            // Top Right: Actions
            Positioned(
              top: AppSpacing.s,
              right: AppSpacing.s,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (latitude != null && longitude != null) ...[
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA4335),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.place, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Google Maps',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  GestureDetector(
                    onTap: () => context.go('/map?location=${Uri.encodeComponent(locationName)}'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_outlined, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Full Map',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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

class _CampusGridPainter extends CustomPainter {
  final bool isDark;
  _CampusGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isDark ? const Color(0xFF1E2126) : const Color(0xFFDDE1E6)
      ..strokeWidth = 1.0;

    // Draw background campus pedestrian paths
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), linePaint);
    }
    for (double j = 0; j < size.height; j += 40) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), linePaint);
    }

    final buildingPaint = Paint()
      ..color = isDark ? const Color(0xFF282C34) : const Color(0xFFCFD5DD)
      ..style = PaintingStyle.fill;

    // Abstract campus building blocks
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(20, 20, 60, 45), const Radius.circular(6)),
      buildingPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 90, 30, 70, 50), const Radius.circular(6)),
      buildingPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(30, size.height - 70, 80, 45), const Radius.circular(6)),
      buildingPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 100, size.height - 65, 75, 45), const Radius.circular(6)),
      buildingPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
