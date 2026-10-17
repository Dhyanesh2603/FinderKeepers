import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../chat/presentation/widgets/embedded_chat_widget.dart';
import '../../../item/data/item_repository.dart';
import '../../../item/domain/models/item.dart';
import '../../data/claim_repository.dart';
import '../../domain/models/claim.dart';

/// Screen allowing item reporters to review and verify submitted ownership claims.
class ManageClaimsScreen extends ConsumerWidget {
  final String itemId;

  const ManageClaimsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(itemByIdProvider(itemId));
    final claims = ref.watch(claimsForItemProvider(itemId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Ownership Claims'),
      ),
      body: claims.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 48,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    const Text(
                      'No claims submitted yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'When students submit ownership claims for "${item?.title ?? "this item"}", they will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: AppSpacing.screenPadding,
              itemCount: claims.length,
              separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.l),
              itemBuilder: (context, index) {
                final claim = claims[index];
                final isApproved = claim.status == ClaimStatus.approved;
                final isPending = claim.status == ClaimStatus.pending;

                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Claimant Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.surfaceVariantLight,
                            child: Text(
                              claim.claimantName.isNotEmpty ? claim.claimantName[0] : 'S',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  claim.claimantName,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  claim.claimantEmail,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(claim.status),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
                        child: Divider(),
                      ),

                      // Verification Answers List
                      const Text(
                        'Submitted Verification Answers:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      ...claim.answers.entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                          padding: const EdgeInsets.all(AppSpacing.s),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.surfaceVariantLight,
                            borderRadius: AppSpacing.borderRadiusSmall,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q: ${entry.key}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'A: "${entry.value}"',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: AppSpacing.m),

                      // Action Buttons
                      if (isPending) ...[
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Reject',
                                variant: AppButtonVariant.outline,
                                onPressed: () async {
                                  await ref
                                      .read(claimRepositoryProvider)
                                      .updateClaimStatus(claim.id, ClaimStatus.rejected);
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Expanded(
                              child: AppButton(
                                label: 'Approve & Chat',
                                onPressed: () async {
                                  await ref
                                      .read(claimRepositoryProvider)
                                      .updateClaimStatus(claim.id, ClaimStatus.approved);
                                  await ref
                                      .read(itemRepositoryProvider)
                                      .updateItemStatus(itemId, ItemStatus.claimPending);
                                  if (context.mounted) {
                                    context.go('/chat/${claim.id}');
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ] else if (isApproved) ...[
                        const SizedBox(height: AppSpacing.s),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.mutedGreenLight,
                            borderRadius: AppSpacing.borderRadiusSmall,
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: AppColors.mutedGreen),
                              SizedBox(width: 6),
                              Text(
                                'Claim Verified & Handover Active',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF14532D)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        EmbeddedChatWidget(claimId: claim.id),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusBadge(ClaimStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case ClaimStatus.approved:
        bg = AppColors.mutedGreenLight;
        fg = AppColors.mutedGreen;
        label = 'Approved';
        break;
      case ClaimStatus.rejected:
        bg = AppColors.mutedRedLight;
        fg = AppColors.mutedRed;
        label = 'Rejected';
        break;
      case ClaimStatus.pending:
        bg = AppColors.mutedAmberLight;
        fg = AppColors.mutedAmber;
        label = 'Pending Review';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
