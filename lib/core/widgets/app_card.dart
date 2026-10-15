import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// A card surface with subtle hairline border and comfortable breathing padding.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBackground = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final defaultBorder = Border.all(
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
      width: 1.0,
    );

    final cardContent = Container(
      padding: padding ?? AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBackground,
        borderRadius: AppSpacing.borderRadiusLarge,
        border: border ?? defaultBorder,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );

    if (onTap == null) {
      return cardContent;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: AppSpacing.borderRadiusLarge,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusLarge,
        child: cardContent,
      ),
    );
  }
}
