import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../claim/data/claim_repository.dart';
import '../../../claim/domain/models/claim.dart';
import '../../../item/data/item_repository.dart';
import '../../../item/domain/models/item.dart';

/// Campus Security & Administrative Moderation Dashboard.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> with SingleTickerProviderStateMixin {
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
    final items = ref.watch(itemsStreamProvider).value ?? [];
    final claims = ref.watch(claimsStreamProvider).value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final reunitedCount = items.where((i) => i.status == ItemStatus.reunited).length;
    final openCount = items.where((i) => i.status == ItemStatus.open).length;
    final recoveryRate = items.isEmpty ? 0 : ((reunitedCount / items.length) * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Campus Security & Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? Colors.white : AppColors.charcoal,
          indicatorColor: isDark ? Colors.white : AppColors.charcoal,
          tabs: [
            Tab(text: 'Items Moderation (${items.length})'),
            Tab(text: 'Claims Audit (${claims.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Metrics Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric('Total Items', '${items.length}', Colors.blueAccent),
                _buildMetric('Active Lost/Found', '$openCount', AppColors.mutedAmber),
                _buildMetric('Reunited', '$reunitedCount', AppColors.mutedGreen),
                _buildMetric('Recovery Rate', '$recoveryRate%', AppColors.mutedGreen),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Items Moderation
                ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.m),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              _buildStatusBadge(item.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reported by ${item.reporterName} • ${item.approximateLocation}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (item.status != ItemStatus.reunited)
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    foregroundColor: AppColors.mutedGreen,
                                  ),
                                  onPressed: () async {
                                    await ref.read(itemRepositoryProvider).updateItemStatus(item.id, ItemStatus.reunited);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Item "${item.title}" marked as REUNITED.')),
                                      );
                                    }
                                  },
                                  child: const Text('Mark Reunited', style: TextStyle(fontSize: 12)),
                                ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  foregroundColor: Colors.redAccent,
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Item "${item.title}" flagged for administrative review.')),
                                  );
                                },
                                child: const Text('Flag / Review', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Tab 2: Claims Audit
                ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: claims.length,
                  separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.m),
                  itemBuilder: (context, index) {
                    final claim = claims[index];
                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                claim.itemTitle,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              _buildClaimBadge(claim.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Claimant: ${claim.claimantName} (${claim.claimantEmail})',
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.s),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                              borderRadius: AppSpacing.borderRadiusSmall,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: claim.answers.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'Q: ${entry.key}\nA: ${entry.value}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => context.push('/items/${claim.itemId}'),
                                child: const Text('Inspect Item', style: TextStyle(fontSize: 12)),
                              ),
                              if (claim.status == ClaimStatus.approved)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? Colors.white : AppColors.charcoal,
                                    foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  onPressed: () => context.push('/chat/${claim.id}'),
                                  child: const Text('Open Security Chat', style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildStatusBadge(ItemStatus status) {
    Color color;
    switch (status) {
      case ItemStatus.open:
        color = AppColors.mutedAmber;
        break;
      case ItemStatus.claimPending:
        color = Colors.blueAccent;
        break;
      case ItemStatus.reunited:
        color = AppColors.mutedGreen;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildClaimBadge(ClaimStatus status) {
    Color color;
    switch (status) {
      case ClaimStatus.pending:
        color = AppColors.mutedAmber;
        break;
      case ClaimStatus.approved:
        color = AppColors.mutedGreen;
        break;
      case ClaimStatus.rejected:
        color = Colors.redAccent;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
