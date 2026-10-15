import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

/// The introductory screen establishing Finders Keepers' calm, minimal design language.
///
/// Fully responsive: adapts gracefully to small phones, standard phones, and tablets
/// using a scrollable viewport constraint.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (AppSpacing.m * 2),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.l),

                      // Campus Community Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.mutedGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Campus Network Active',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.l),

                      // Title and Mission Statement
                      Text(
                        'Finders\nKeepers.',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 40,
                          height: 1.05,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.s),

                      Text(
                        'A student-first platform to report lost items, verify ownership, and reunite safely on campus.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Key Principles Cards
                      AppCard(
                        child: Column(
                          children: [
                            _buildFeatureRow(
                              context,
                              icon: Icons.shield_outlined,
                              title: 'Privacy-First Approximate Locations',
                              subtitle: 'Exact coordinates stay private until claims are verified.',
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
                              child: Divider(),
                            ),
                            _buildFeatureRow(
                              context,
                              icon: Icons.verified_user_outlined,
                              title: 'Structured Ownership Verification',
                              subtitle: 'Answer unique identifying questions before item handover.',
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: AppSpacing.l),

                      // Action Button
                      AppButton(
                        label: 'Enter Campus Hub',
                        onPressed: () => context.go('/login'),
                      ),

                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
            borderRadius: AppSpacing.borderRadiusSmall,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.textPrimaryDark : AppColors.charcoal,
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
