import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../claim/data/claim_repository.dart';
import '../../../claim/domain/models/claim.dart';
import '../../../item/data/item_repository.dart';
import '../../../item/domain/models/item.dart';

/// Screen displaying student profile, categorized activity (Lost reports, Found reports, Claims),
/// and recovery statistics.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final allItems = ref.watch(itemsStreamProvider).value ?? [];
    final allClaims = ref.watch(claimsStreamProvider).value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveUserId = user?.uid ?? 'user_001';

    // Categorized items
    final myLostItems = allItems
        .where((i) => i.reporterId == effectiveUserId && i.type == ItemType.lost)
        .toList();

    final myFoundItems = allItems
        .where((i) => i.reporterId == effectiveUserId && i.type == ItemType.found)
        .toList();

    final myClaims = allClaims
        .where((c) => c.claimantId == effectiveUserId)
        .toList();

    final reunitedCount = myLostItems.where((i) => i.status == ItemStatus.reunited).length +
        myFoundItems.where((i) => i.status == ItemStatus.reunited).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile & Activity'),
        leading: const AppBackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add_rounded),
            tooltip: 'Report Item',
            onPressed: () => context.push('/report'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Student Profile Identity Card
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.s),
              child: AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariantLight,
                      child: Text(
                        (user?.displayName.isNotEmpty ?? false)
                            ? user!.displayName[0].toUpperCase()
                            : 'A',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.charcoal,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Alex Rivers (Demo Student)',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${user?.studentId ?? "24CS1092"} • ${user?.email ?? "student@campus.edu"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mutedGreenLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 13, color: AppColors.mutedGreen),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.mutedGreen),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Activity Statistics Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  _buildStatTile(
                    label: 'Lost',
                    count: myLostItems.length,
                    icon: Icons.search_rounded,
                    color: AppColors.mutedAmber,
                    isDark: isDark,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  _buildStatTile(
                    label: 'Found',
                    count: myFoundItems.length,
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.mutedGreen,
                    isDark: isDark,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  _buildStatTile(
                    label: 'Claims',
                    count: myClaims.length,
                    icon: Icons.pan_tool_outlined,
                    color: AppColors.mutedBlue,
                    isDark: isDark,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  _buildStatTile(
                    label: 'Reunited',
                    count: reunitedCount,
                    icon: Icons.celebration_outlined,
                    color: Colors.purpleAccent,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            // Tab bar for Lost Items vs Found Items vs Claims
            TabBar(
              controller: _tabController,
              labelColor: isDark ? Colors.white : AppColors.charcoal,
              unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              indicatorColor: isDark ? Colors.white : AppColors.charcoal,
              isScrollable: false,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Lost ('),
                      Text('${myLostItems.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text(')'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Found ('),
                      Text('${myFoundItems.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text(')'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Claims ('),
                      Text('${myClaims.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text(')'),
                    ],
                  ),
                ),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Things I Lost
                  _buildLostItemsTab(myLostItems, isDark),

                  // Tab 2: Things I Found
                  _buildFoundItemsTab(myFoundItems, allClaims, isDark),

                  // Tab 3: My Claims
                  _buildClaimsTab(myClaims, isDark),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.m),
              child: AppButton(
                label: 'Sign Out of Campus Hub',
                variant: AppButtonVariant.outline,
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.charcoal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLostItemsTab(List<Item> lostItems, bool isDark) {
    if (lostItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              const SizedBox(height: AppSpacing.m),
              const Text('No Lost Items Reported', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Misplaced your keys, ID card, or backpack? Post a lost report so finders can verify and return it.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: AppSpacing.l),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Report a Lost Item'),
                onPressed: () => context.push('/report'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: AppSpacing.screenPadding,
      itemCount: lostItems.length,
      separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.s),
      itemBuilder: (context, index) {
        final item = lostItems[index];
        final isReunited = item.status == ItemStatus.reunited;

        return AppCard(
          onTap: () => context.push('/items/${item.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.mutedAmberLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: const Text(
                      'LOST',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.mutedAmber),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    isReunited ? 'Reunited ✓' : 'Searching',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isReunited ? AppColors.mutedGreen : AppColors.mutedAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.approximateLocation,
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (item.latitude != null && item.longitude != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.map_outlined, size: 13, color: AppColors.mutedBlue),
                    const SizedBox(width: 4),
                    Text(
                      'GPS: ${item.latitude!.toStringAsFixed(4)}° N, ${item.longitude!.toStringAsFixed(4)}° E',
                      style: const TextStyle(fontSize: 11, color: AppColors.mutedBlue),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 30),
                    ),
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                    label: const Text('View Listing', style: TextStyle(fontSize: 12)),
                    onPressed: () => context.push('/items/${item.id}'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoundItemsTab(List<Item> foundItems, List<Claim> allClaims, bool isDark) {
    if (foundItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              const SizedBox(height: AppSpacing.m),
              const Text('No Found Items Reported', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Found student property on campus? Report it with secret verification questions to safely return it.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: AppSpacing.l),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Report a Found Item'),
                onPressed: () => context.push('/report'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: AppSpacing.screenPadding,
      itemCount: foundItems.length,
      separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.s),
      itemBuilder: (context, index) {
        final item = foundItems[index];
        final isReunited = item.status == ItemStatus.reunited;
        final itemClaims = allClaims.where((c) => c.itemId == item.id).toList();

        return AppCard(
          onTap: () => context.push('/items/${item.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.mutedGreenLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: const Text(
                      'FOUND',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.mutedGreen),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    isReunited ? 'Reunited ✓' : 'In Custody',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isReunited ? AppColors.mutedGreen : AppColors.mutedBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.approximateLocation,
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (item.latitude != null && item.longitude != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.pin_drop_outlined, size: 13, color: AppColors.mutedGreen),
                    const SizedBox(width: 4),
                    Text(
                      'Tagged: ${item.latitude!.toStringAsFixed(4)}° N, ${item.longitude!.toStringAsFixed(4)}° E',
                      style: const TextStyle(fontSize: 11, color: AppColors.mutedGreen),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: itemClaims.isNotEmpty
                          ? AppColors.mutedAmberLight
                          : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Text(
                      itemClaims.isNotEmpty
                          ? '⚡ ${itemClaims.length} Claim(s) Received'
                          : 'No claims yet',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: itemClaims.isNotEmpty
                            ? AppColors.mutedAmber
                            : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (itemClaims.isNotEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mutedGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 30),
                          ),
                          icon: const Icon(Icons.how_to_reg_outlined, size: 14),
                          label: Text('Review Claims (${itemClaims.length})', style: const TextStyle(fontSize: 11)),
                          onPressed: () => context.push('/items/${item.id}/claims'),
                        ),
                      if (itemClaims.isEmpty)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 30),
                          ),
                          icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                          label: const Text('View Listing', style: TextStyle(fontSize: 12)),
                          onPressed: () => context.push('/items/${item.id}'),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClaimsTab(List<Claim> claims, bool isDark) {
    if (claims.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pan_tool_outlined, size: 48, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              const SizedBox(height: AppSpacing.m),
              const Text('No Ownership Claims Submitted', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Spot an item you lost in the campus feed? Submit an ownership claim by answering the finder\'s secret challenge.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: AppSpacing.l),
              ElevatedButton.icon(
                icon: const Icon(Icons.explore_outlined, size: 16),
                label: const Text('Browse Campus Feed'),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: AppSpacing.screenPadding,
      itemCount: claims.length,
      separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.s),
      itemBuilder: (context, index) {
        final claim = claims[index];
        final isApproved = claim.status == ClaimStatus.approved;
        final isRejected = claim.status == ClaimStatus.rejected;

        Color statusColor = AppColors.mutedAmber;
        String statusLabel = 'PENDING REVIEW';
        if (isApproved) {
          statusColor = AppColors.mutedGreen;
          statusLabel = 'APPROVED ✓';
        } else if (isRejected) {
          statusColor = Colors.redAccent;
          statusLabel = 'REJECTED';
        }

        return AppCard(
          onTap: () => context.push('/items/${claim.itemId}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      claim.itemTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isApproved
                    ? '🎉 Ownership confirmed by finder! Safe handover unlocked.'
                    : (isRejected
                        ? 'Verification did not match. You may revise or speak with campus security.'
                        : 'Finder is reviewing your secret answers. Only one claim permitted at a time.'),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 30),
                    ),
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                    label: const Text('View Item', style: TextStyle(fontSize: 12)),
                    onPressed: () => context.push('/items/${claim.itemId}'),
                  ),
                  if (isApproved) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mutedGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: const Size(0, 30),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 14),
                      label: const Text('Handover Chat', style: TextStyle(fontSize: 12)),
                      onPressed: () => context.push('/chat/${claim.id}'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
