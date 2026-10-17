import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/offline_service.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../item/data/item_repository.dart';
import '../../../item/domain/models/item.dart';
import '../../../notifications/data/match_engine.dart';
import '../../../item/presentation/widgets/campus_map_explorer.dart';
import '../controllers/feed_controller.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/item_card.dart';

/// The primary campus discovery hub where students browse lost and found listings.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isMapView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final items = ref.watch(filteredItemsProvider);
    final selectedType = ref.watch(selectedTypeFilterProvider);
    final isOffline = ref.watch(isOfflineModeProvider);
    final matches = ref.watch(matchRecommendationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Finders Keepers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              user?.displayName != null
                  ? '${user!.displayName} • ${user.studentId}'
                  : 'Campus Community',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          // Offline / Online Mode Toggle Simulator
          IconButton(
            icon: Icon(
              isOffline ? Icons.wifi_off : Icons.wifi,
              size: 20,
              color: isOffline ? Colors.orangeAccent : AppColors.mutedGreen,
            ),
            tooltip: isOffline ? 'Offline Mode Active' : 'Online Mode Active',
            onPressed: () async {
              ref.read(isOfflineModeProvider.notifier).toggle();
              final nowOffline = ref.read(isOfflineModeProvider);
              if (!nowOffline) {
                final queued = await OfflineService.drainOfflineQueue();
                for (final item in queued) {
                  await ref.read(itemRepositoryProvider).addItem(item);
                }
                if (context.mounted && queued.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Auto-synced ${queued.length} offline report(s)!'),
                      backgroundColor: AppColors.mutedGreen,
                    ),
                  );
                }
              }
            },
          ),
          // Smart Match Alerts Button
          IconButton(
            icon: Badge(
              isLabelVisible: matches.isNotEmpty,
              label: Text('${matches.length}'),
              child: const Icon(Icons.notifications_outlined, size: 22),
            ),
            tooltip: 'Smart Match Alerts',
            onPressed: () => context.go('/notifications'),
          ),
          // Campus Map Explorer Toggle
          IconButton(
            icon: Icon(
              _isMapView ? Icons.view_agenda_outlined : Icons.map_outlined,
              size: 22,
              color: _isMapView ? AppColors.mutedGreen : null,
            ),
            tooltip: _isMapView ? 'Feed List View' : 'Campus Map Explorer',
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
          // Campus Security Admin Console
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined, size: 22),
            tooltip: 'Campus Security & Admin',
            onPressed: () => context.go('/admin'),
          ),
          // Profile & Claims
          IconButton(
            icon: const Icon(Icons.person_outline, size: 22),
            tooltip: 'My Profile & Claims',
            onPressed: () => context.go('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, size: 20),
            tooltip: 'Sign Out',
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? Colors.white : AppColors.charcoal,
        foregroundColor: isDark ? AppColors.charcoal : Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Report Item',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        onPressed: () => context.go('/report'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offline Warning & Sync Banner
            if (isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 8),
                color: Colors.orangeAccent.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, size: 16, color: Colors.orangeAccent),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Offline Mode Active • Drafts & reports queue locally',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orangeAccent),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      onPressed: () async {
                        ref.read(isOfflineModeProvider.notifier).setOffline(false);
                        final queued = await OfflineService.drainOfflineQueue();
                        for (final item in queued) {
                          await ref.read(itemRepositoryProvider).addItem(item);
                        }
                        if (context.mounted && queued.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Auto-synced ${queued.length} offline report(s)!'),
                              backgroundColor: AppColors.mutedGreen,
                            ),
                          );
                        }
                      },
                      child: const Text('Go Online', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).update(val);
                },
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search items, locations, keywords...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).clear();
                            setState(() {});
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.s),

            // View Mode Switcher: Feed List vs. Campus Map
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Row(
                  children: [
                    _buildModeTab(
                      label: 'Feed List',
                      icon: Icons.view_agenda_outlined,
                      isSelected: !_isMapView,
                      onTap: () => setState(() => _isMapView = false),
                    ),
                    _buildModeTab(
                      label: 'Campus Map',
                      icon: Icons.map_outlined,
                      isSelected: _isMapView,
                      onTap: () => setState(() => _isMapView = true),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.m),

            if (_isMapView)
              Expanded(
                child: CampusMapExplorerWidget(
                  filterType: selectedType,
                ),
              )
            else ...[
              // Segmented Type Pill Switcher (All, Lost, Found)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Row(
                  children: [
                    _buildTypeTab(
                      label: 'All Items',
                      isSelected: selectedType == null,
                      onTap: () => ref
                          .read(selectedTypeFilterProvider.notifier)
                          .select(null),
                    ),
                    _buildTypeTab(
                      label: 'Lost',
                      isSelected: selectedType == ItemType.lost,
                      onTap: () => ref
                          .read(selectedTypeFilterProvider.notifier)
                          .select(ItemType.lost),
                    ),
                    _buildTypeTab(
                      label: 'Found',
                      isSelected: selectedType == ItemType.found,
                      onTap: () => ref
                          .read(selectedTypeFilterProvider.notifier)
                          .select(ItemType.found),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.m),

            // Category Filter Chips
            const CategoryFilterChips(),

            const SizedBox(height: AppSpacing.m),

            // Feed Header Counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                '${items.length} ${items.length == 1 ? 'item' : 'items'} found',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  letterSpacing: 0.2,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            // Items List / Empty State
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.separated(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.xl,
                          right: AppSpacing.xl,
                          top: AppSpacing.xs,
                          bottom: 80, // Space for FAB
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: AppSpacing.m),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ItemCard(
                            item: item,
                            onTap: () => context.go('/items/${item.id}'),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.surfaceDark : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.charcoal)
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.charcoal)
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.surfaceDark : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.charcoal)
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 48,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'No matching items',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try clearing your search query or switching to "All Items".',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
