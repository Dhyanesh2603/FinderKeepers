import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../chat/presentation/widgets/embedded_chat_widget.dart';
import '../../../claim/data/claim_repository.dart';
import '../../../claim/domain/models/claim.dart';
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
        appBar: AppBar(
          leading: const AppBackButton(),
        ),
        body: const Center(child: Text('Item listing not found.')),
      );
    }

    final isOwner = currentUser != null && currentUser.uid == item.reporterId;
    final isLost = item.type == ItemType.lost;
    final userClaim = claims.where((c) => c.claimantId == currentUser?.uid).firstOrNull;
    final approvedClaimForOwner = isOwner ? claims.where((c) => c.status == ClaimStatus.approved).firstOrNull : null;
    final activeChatClaimId = isOwner ? approvedClaimForOwner?.id : (userClaim?.status == ClaimStatus.approved ? userClaim?.id : null);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
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
                        onPressed: () => context.push('/items/$itemId/claims'),
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
                      : (userClaim == null
                          ? 'Claim This Item'
                          : (userClaim.status == ClaimStatus.pending
                              ? 'Claim Pending Review ⏳'
                              : (userClaim.status == ClaimStatus.approved
                                  ? 'Claim Approved • Open Chat 💬'
                                  : 'Claim Rejected • Re-apply'))),
                  onPressed: item.status == ItemStatus.reunited
                      ? null
                      : () => context.push('/items/$itemId/claim'),
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
            // Anti-Fraud Verification Questions Section
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.m),
              backgroundColor: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.mutedGreenLight.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.mutedGreen, size: 22),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          'Ownership Verification Quiz (${item.verificationQuestions.length})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (!isOwner && item.status != ItemStatus.reunited)
                        InkWell(
                          onTap: () => context.push('/items/$itemId/claim'),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.mutedGreen,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                            ),
                            child: const Text(
                              'Answer',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOwner
                        ? 'You posted these verification questions to verify genuine ownership before returning the item:'
                        : 'To claim this item, answer the following questions posted by the finder:',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  if (item.verificationQuestions.isEmpty)
                    const Text(
                      'No custom questions posted. Standard campus proof of ownership applies.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    )
                  else
                    ...item.verificationQuestions.asMap().entries.map((entry) {
                      final qNum = entry.key + 1;
                      final qText = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.mutedGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Q$qNum',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.mutedGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                qText,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),

            if (activeChatClaimId != null) ...[
              const SizedBox(height: AppSpacing.l),
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.mutedGreenLight,
                  borderRadius: AppSpacing.borderRadiusMedium,
                  border: Border.all(color: AppColors.mutedGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 20, color: AppColors.mutedGreen),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Text(
                        isOwner
                            ? 'Claim verified! You can chat directly with the verified owner below to coordinate handover.'
                            : 'Your ownership claim was verified! Chat with the finder below to arrange safe handover.',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF14532D)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              EmbeddedChatWidget(claimId: activeChatClaimId),
            ],

            const SizedBox(height: AppSpacing.l),

            // Approximate Campus Location Map
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Approximate Campus Location',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (item.latitude != null && item.longitude != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.open_in_new, size: 14, color: Colors.blueAccent),
                    label: const Text(
                      'Google Maps',
                      style: TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () async {
                      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}');
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            CampusMapWidget(
              locationName: item.approximateLocation,
              latitude: item.latitude,
              longitude: item.longitude,
            ),

            if (item.latitude != null && item.longitude != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariantDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place, size: 14, color: Color(0xFFEA4335)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tagged GPS Pin: ${item.latitude!.toStringAsFixed(6)}° N, ${item.longitude!.toStringAsFixed(6)}° E',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
