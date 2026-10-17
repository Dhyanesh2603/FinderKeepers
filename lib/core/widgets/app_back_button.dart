import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';

/// Standard, high-contrast back button used across all screens.
///
/// Reliably navigates to the previous screen in the stack using [context.pop()],
/// or gracefully falls back to [context.go('/home')] if there is no previous history,
/// preventing accidental app closure.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onBack;
  final Color? color;
  final String tooltip;

  const AppBackButton({
    super.key,
    this.onBack,
    this.color,
    this.tooltip = 'Back to previous page',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white : AppColors.charcoal;

    return IconButton(
      icon: Icon(Icons.arrow_back, color: color ?? defaultColor),
      tooltip: tooltip,
      onPressed: onBack ??
          () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
    );
  }
}
