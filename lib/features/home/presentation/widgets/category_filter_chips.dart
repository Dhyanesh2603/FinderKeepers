import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../item/domain/models/item.dart';
import '../controllers/feed_controller.dart';

/// Horizontal scrolling list of categories adhering to the minimal monochrome design.
class CategoryFilterChips extends ConsumerWidget {
  const CategoryFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: ItemCategory.values.length,
        separatorBuilder: (_, index) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final category = ItemCategory.values[index];
          final isSelected = category == selectedCategory;

          final backgroundColor = isSelected
              ? (isDark ? Colors.white : AppColors.charcoal)
              : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight);

          final textColor = isSelected
              ? (isDark ? AppColors.charcoal : Colors.white)
              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

          final borderColor = isSelected
              ? Colors.transparent
              : (isDark ? AppColors.borderDark : AppColors.borderLight);

          return Material(
            color: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              side: BorderSide(color: borderColor, width: 1.0),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              onTap: () {
                ref
                    .read(selectedCategoryFilterProvider.notifier)
                    .select(category);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.xxs,
                ),
                child: Center(
                  child: Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
