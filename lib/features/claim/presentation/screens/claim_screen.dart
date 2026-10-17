import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../chat/presentation/widgets/embedded_chat_widget.dart';
import '../../../item/data/item_repository.dart';
import '../../../item/domain/models/item.dart';
import '../../data/claim_repository.dart';
import '../../domain/models/claim.dart';

/// Screen where claimants answer owner verification questions to establish authentic ownership.
class ClaimScreen extends ConsumerStatefulWidget {
  final String itemId;

  const ClaimScreen({super.key, required this.itemId});

  @override
  ConsumerState<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends ConsumerState<ClaimScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitClaim(Item item) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final answers = <String, String>{};
    for (final q in item.verificationQuestions) {
      final answerText = _controllers[q]?.text.trim() ?? '';
      if (answerText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please answer all verification questions.')),
        );
        return;
      }
      answers[q] = answerText;
    }

    setState(() => _isSubmitting = true);

    final newClaim = Claim(
      id: 'claim_${DateTime.now().millisecondsSinceEpoch}',
      itemId: item.id,
      itemTitle: item.title,
      claimantId: currentUser.uid,
      claimantName: currentUser.displayName,
      claimantEmail: currentUser.email,
      answers: answers,
      status: ClaimStatus.pending,
      createdAt: DateTime.now(),
    );

    // Save claim and update item status to claimPending
    await ref.read(claimRepositoryProvider).submitClaim(newClaim);
    await ref.read(itemRepositoryProvider).updateItemStatus(item.id, ItemStatus.claimPending);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Claim submitted! The reporter will review your verification answers.'),
        backgroundColor: AppColors.mutedGreen,
      ),
    );
    context.go('/items/${item.id}');
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(itemByIdProvider(widget.itemId));
    final claims = ref.watch(claimsForItemProvider(widget.itemId));
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Item not found.')),
      );
    }

    final isReporter = currentUser != null && currentUser.uid == item.reporterId;
    final approvedClaim = claims.where((c) => c.status == ClaimStatus.approved).firstOrNull;

    // Find the latest claim submitted by this specific user
    final existingClaim = claims.where((c) => c.claimantId == currentUser?.uid).firstOrNull;
    final isPending = existingClaim != null && existingClaim.status == ClaimStatus.pending;
    final isApproved = existingClaim != null && existingClaim.status == ClaimStatus.approved;
    final isRejected = existingClaim != null && existingClaim.status == ClaimStatus.rejected;

    // Initialize text controllers for verification questions
    for (final q in item.verificationQuestions) {
      _controllers.putIfAbsent(q, () => TextEditingController());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isReporter
              ? (approvedClaim != null ? 'Handover & Chat' : 'Item Reporter Dashboard')
              : (isApproved ? 'Handover & Chat' : 'Verify Ownership'),
        ),
      ),
      bottomNavigationBar: (isApproved || isPending || isReporter)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.s),
                child: AppButton(
                  label: isRejected ? 'Submit Revised Claim' : 'Submit Ownership Claim',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : () => _submitClaim(item),
                ),
              ),
            ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item reference header
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 24, color: AppColors.mutedAmber),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          item.approximateLocation,
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

            if (isReporter) ...[
              if (approvedClaim != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: AppColors.mutedGreenLight,
                    borderRadius: AppSpacing.borderRadiusMedium,
                    border: Border.all(color: AppColors.mutedGreen.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, size: 22, color: AppColors.mutedGreen),
                      SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          'Claim Verified! Coordinate physical pickup with the student below in the handover chat.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF14532D)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                EmbeddedChatWidget(claimId: approvedClaim.id),
                const SizedBox(height: 30),
              ] else ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.mutedAmber, size: 22),
                          SizedBox(width: 8),
                          Text('You Reported This Item', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        'As the finder/reporter of this item, you do not submit claims for yourself. Instead, you can review and verify ownership quiz responses submitted by other students.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      AppButton(
                        label: 'Review Submitted Claims (${claims.length})',
                        onPressed: () => context.go('/items/${item.id}/claims'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ] else if (isApproved) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.mutedGreenLight,
                  borderRadius: AppSpacing.borderRadiusMedium,
                  border: Border.all(color: AppColors.mutedGreen.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, size: 22, color: AppColors.mutedGreen),
                    SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Text(
                        'Claim Approved & Verified! You can now use the embedded handover chat below to arrange a safe physical pickup.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF14532D)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              EmbeddedChatWidget(claimId: existingClaim.id),
              const SizedBox(height: 30),
            ] else if (isPending) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.mutedAmberLight,
                  borderRadius: AppSpacing.borderRadiusMedium,
                  border: Border.all(color: AppColors.mutedAmber.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top_outlined, size: 22, color: AppColors.mutedAmber),
                    SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Text(
                        'Claim Pending Review: You already have an active claim under review by the finder. Only one claim is permitted at a time.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7A4A0A)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Submitted Answers:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.s),
                    ...existingClaim.answers.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              entry.value,
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ] else ...[
              if (isRejected)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.l),
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.borderRadiusMedium,
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.redAccent),
                      SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          'Your previous claim was rejected. You can now re-apply with corrected or additional proof below.',
                          style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              // Anti-Fraud Honor Code Warning
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.mutedAmberLight,
                  borderRadius: AppSpacing.borderRadiusMedium,
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, size: 20, color: AppColors.mutedAmber),
                    SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Text(
                        'Anti-Fraud Verification: To protect students from fraudulent pickups, answers are securely transmitted to the finder. False claims are reported to campus security.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A4A0A),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Owner Verification Questions (${item.verificationQuestions.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Answer these questions specifically to prove this item belongs to you.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),

              const SizedBox(height: AppSpacing.l),

              ...item.verificationQuestions.map((question) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.l),
                  child: AppTextField(
                    label: question,
                    hintText: 'Enter your specific answer...',
                    controller: _controllers[question],
                  ),
                );
              }),

              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}
