import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../widgets/campus_map_explorer.dart';

/// Full-screen Campus Map Explorer showing all lost & found items on university landmarks.
class CampusMapScreen extends StatelessWidget {
  final String? initialLocation;

  const CampusMapScreen({super.key, this.initialLocation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campus Map Explorer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'Interactive zones with approximate privacy fuzzing (~100m)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.mutedGreen),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Report Item at Campus Location',
            onPressed: () => context.push('/report'),
          ),
        ],
      ),
      body: CampusMapExplorerWidget(
        initialSelectedLocation: initialLocation,
      ),
    );
  }
}
