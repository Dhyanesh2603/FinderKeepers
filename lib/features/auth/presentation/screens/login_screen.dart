import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/auth_repository.dart';
import '../controllers/auth_controller.dart';

/// Minimal, student-focused login screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoCredentials() {
    setState(() {
      _emailController.text = 'student@campus.edu';
      _passwordController.text = 'password123';
      _emailError = null;
    });
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final validationError = InMemoryAuthRepository.validateCampusEmail(email);
    if (validationError != null) {
      setState(() => _emailError = validationError);
      return;
    }
    setState(() => _emailError = null);

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password.')),
      );
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .signIn(email, password);

    if (!mounted) return;

    if (!success) {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString().replaceAll('Exception: ', '') ?? 'Authentication failed.'),
          backgroundColor: AppColors.mutedRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.s),
              Text(
                'Student Sign In',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Use your official university email to access the lost & found hub.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Demo credentials pill for easy interview testing
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.s,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 20, color: AppColors.mutedAmber),
                    const SizedBox(width: AppSpacing.s),
                    const Expanded(
                      child: Text(
                        'Demo: student@campus.edu',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton(
                      onPressed: _fillDemoCredentials,
                      child: const Text('Auto-fill', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              AppTextField(
                label: 'Campus Email',
                hintText: 'e.g. yourname@campus.edu',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                errorText: _emailError,
              ),
              const SizedBox(height: AppSpacing.m),

              AppTextField(
                label: 'Password',
                hintText: 'Enter your password',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
              ),

              const SizedBox(height: AppSpacing.xxl),

              AppButton(
                label: 'Sign In to Hub',
                isLoading: isLoading,
                onPressed: isLoading ? null : _handleLogin,
              ),

              const SizedBox(height: AppSpacing.l),

              Center(
                child: TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text(
                    "New to campus? Register your student account",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
