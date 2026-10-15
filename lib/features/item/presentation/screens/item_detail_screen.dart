import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../claim/data/claim_repository.dart';
import '../../data/item_repository.dart';
import '../../domain/models/item.dart';
import '../widgets/campus_map_widget.dart';

/// Detailed view of a campus item featuring status timeline, privacy map, and claim actions.
class ItemDetailScreen extends ConsumerWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(itemByIdProvider(itemId));
    final currentUser = ref.watch(currentUserProvider);
    final claims = ref.watch(claimsForItemProvider(itemId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Item listing not found.')),
      );
    }

    final isOwner = currentUser != null && currentUser.uid == item.reporterId;
    final isLost = item.type == ItemType.lost;

    return Scaffold(
      appBar: AppBar(
        title: Text(isLost ? 'Lost Item Details' : 'Found Item Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item link copied to campus clipboard.')),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.s),
          child: isOwner
              ? Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Claims (${claims.length})',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => context.go('/items/$itemId/claims'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: AppButton(
                        label: item.status == ItemStatus.reunited ? 'Reunited ✓' : 'Mark Reunited',
                        onPressed: item.status == ItemStatus.reunited
                            ? null
                            : () async {
                                await ref
                                    .read(itemRepositoryProvider)
                                    .updateItemStatus(itemId, ItemStatus.reunited);
                              },
                      ),
                    ),
                  ],
                )
              : AppButton(
                  label: item.status == ItemStatus.reunited
                      ? 'Item Already Reunited'
                      : 'Claim This Item',
                  onPressed: item.status == ItemStatus.reunited
                      ? null
                      : () => context.go('/items/$itemId/claim'),
                ),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Timeline
            _buildStatusTimeline(context, item.status),

            const SizedBox(height: AppSpacing.l),

            // Header Row: Badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLost ? AppColors.mutedAmberLight : AppColors.mutedGreenLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(
                    isLost ? 'LOST' : 'FOUND',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isLost ? AppColors.mutedAmber : AppColors.mutedGreen,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(
                    item.category.label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d, h:mm a').format(item.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.m),

            // Item Title
            Text(
              item.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
            ),

            const SizedBox(height: AppSpacing.xs),

            // Reporter student line
            Text(
              'Reported by ${item.reporterName} • Verified Student',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // Description Box
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Item Description',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // Anti-Fraud Verification Protection Card
            AppCard(
              backgroundColor: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.mutedGreenLight.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, color: AppColors.mutedGreen, size: 24),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Structured Ownership Verification',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.verificationQuestions.length} secret verification questions protect this item from fraudulent claims.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // Approximate Campus Location Map
            const Text(
              'Approximate Campus Location',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            CampusMapWidget(locationName: item.approximateLocation),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(BuildContext context, ItemStatus status) {
    final steps = ['Reported', 'Verification', 'Reunited'];
    int activeIndex = 0;
    if (status == ItemStatus.claimPending) activeIndex = 1;
    if (status == ItemStatus.reunited) activeIndex = 2;

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= activeIndex;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppColors.mutedGreen : Colors.grey.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text('${index + 1}', style: const TextStyle(fontSize: 11, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                  color: isCompleted ? AppColors.mutedGreen : Colors.grey,
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: isCompleted ? AppColors.mutedGreen : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
