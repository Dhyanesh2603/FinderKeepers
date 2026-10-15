import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outline }

/// A reusable, minimal button adhering to the product's calm design language.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = isDark ? Colors.white : AppColors.charcoal;
        textColor = isDark ? AppColors.charcoal : Colors.white;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
        textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        break;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        borderSide = BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.2,
        );
        break;
    }

    final content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 52,
      child: Material(
        color: onPressed == null ? backgroundColor.withValues(alpha: 0.4) : backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMedium,
          side: borderSide,
        ),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppSpacing.borderRadiusMedium,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
