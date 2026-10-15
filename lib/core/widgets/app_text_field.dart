import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// Standard minimal text input field with optional label and icon.
class AppTextField extends StatelessWidget {
  final String? label;
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    this.label,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffix,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final border = OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
      borderSide: BorderSide(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        width: 1.0,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusMedium,
      borderSide: BorderSide(
        color: isDark ? Colors.white70 : AppColors.charcoal,
        width: 1.4,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            filled: true,
            fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
            errorText: errorText,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: 20,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  )
                : null,
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.m,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: focusedBorder,
          ),
        ),
      ],
    );
  }
}
