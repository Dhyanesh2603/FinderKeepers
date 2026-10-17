import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/match_engine.dart';

/// Screen displaying automated match alerts and location-based recommendations.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchRecommendationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Match Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: matches.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 48,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    const Text('No Match Alerts Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Our matching engine monitors new lost and found reports and notifies you when confidence exceeds 50%.',
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
              itemCount: matches.length,
              separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.m),
              itemBuilder: (context, index) {
                final match = matches[index];
                final score = match.confidenceScore;
                final badgeColor = score >= 75
                    ? AppColors.mutedGreen
                    : (score >= 60 ? AppColors.mutedAmber : Colors.blueGrey);

                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome, size: 12, color: badgeColor),
                                const SizedBox(width: 4),
                                Text(
                                  '$score% Match Confidence',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: badgeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            match.lostItem.category.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.s),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                                borderRadius: AppSpacing.borderRadiusSmall,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('LOST ITEM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.redAccent)),
                                  const SizedBox(height: 2),
                                  Text(
                                    match.lostItem.title,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    match.lostItem.approximateLocation,
                                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            child: Icon(Icons.compare_arrows, size: 20, color: Colors.grey),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.s),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                                borderRadius: AppSpacing.borderRadiusSmall,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('FOUND ITEM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.mutedGreen)),
                                  const SizedBox(height: 2),
                                  Text(
                                    match.foundItem.title,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    match.foundItem.approximateLocation,
                                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        'Match Rationale: ${match.rationale}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => context.go('/items/${match.foundItem.id}'),
                            child: const Text('View Found Item', style: TextStyle(fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : AppColors.charcoal,
                              foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () => context.go('/items/${match.foundItem.id}/claim'),
                            child: const Text('Claim This Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
