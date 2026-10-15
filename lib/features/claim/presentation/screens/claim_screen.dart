import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/data/auth_repository.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Item not found.')),
      );
    }

    // Initialize text controllers for verification questions
    for (final q in item.verificationQuestions) {
      _controllers.putIfAbsent(q, () => TextEditingController());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Ownership'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.s),
          child: AppButton(
            label: 'Submit Ownership Claim',
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
        ),
      ),
    );
  }
}
