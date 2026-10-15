import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../claim/data/claim_repository.dart';
import '../../../claim/domain/models/claim.dart';
import '../../../item/data/item_repository.dart';
import '../../../item/domain/models/item.dart';

/// Screen displaying student profile, active reports, and submitted ownership claims.
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
    _tabController = TabController(length: 2, vsync: this);
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

    final myItems = allItems.where((i) => i.reporterId == user?.uid).toList();
    final myClaims = allClaims.where((c) => c.claimantId == user?.uid).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile & Activity'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Student Profile Identity Card
            Padding(
              padding: AppSpacing.screenPadding,
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
                            : 'S',
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
                            user?.displayName ?? 'Student',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${user?.studentId ?? "N/A"} • ${user?.email ?? ""}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.mutedGreenLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: const Text(
                        'Verified',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.mutedGreen),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab bar for Reports vs Claims
            TabBar(
              controller: _tabController,
              labelColor: isDark ? Colors.white : AppColors.charcoal,
              unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              indicatorColor: isDark ? Colors.white : AppColors.charcoal,
              tabs: [
                Tab(text: 'My Reports (${myItems.length})'),
                Tab(text: 'My Claims (${myClaims.length})'),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: My Reported Items
                  myItems.isEmpty
                      ? const Center(child: Text('You have not reported any items yet.'))
                      : ListView.separated(
                          padding: AppSpacing.screenPadding,
                          itemCount: myItems.length,
                          separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.s),
                          itemBuilder: (context, index) {
                            final item = myItems[index];
                            return AppCard(
                              onTap: () => context.go('/items/${item.id}'),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        Text(item.approximateLocation, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    item.status == ItemStatus.reunited ? 'Reunited ✓' : 'Active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: item.status == ItemStatus.reunited ? AppColors.mutedGreen : AppColors.mutedAmber,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                  // Tab 2: My Claims
                  myClaims.isEmpty
                      ? const Center(child: Text('You have not submitted any ownership claims.'))
                      : ListView.separated(
                          padding: AppSpacing.screenPadding,
                          itemCount: myClaims.length,
                          separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.s),
                          itemBuilder: (context, index) {
                            final claim = myClaims[index];
                            return AppCard(
                              onTap: () => context.go('/items/${claim.itemId}'),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(claim.itemTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        Text('Status: ${claim.status.name.toUpperCase()}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                                      ],
                                    ),
                                  ),
                                  if (claim.status == ClaimStatus.approved)
                                    IconButton(
                                      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.mutedGreen),
                                      onPressed: () => context.go('/chat/${claim.id}'),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AppButton(
                label: 'Sign Out of Hub',
                variant: AppButtonVariant.outline,
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
