import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/auth_repository.dart';
import '../controllers/auth_controller.dart';

/// Screen allowing new students to create an account with campus credentials.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final studentId = _studentIdController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in your name and student ID.')),
      );
      return;
    }

    final validationError = InMemoryAuthRepository.validateCampusEmail(email);
    if (validationError != null) {
      setState(() => _emailError = validationError);
      return;
    }
    setState(() => _emailError = null);

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          email: email,
          password: password,
          fullName: name,
          studentId: studentId,
        );

    if (!mounted) return;

    if (!success) {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString().replaceAll('Exception: ', '') ?? 'Registration failed.'),
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
        leading: AppBackButton(
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
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
                'Student Registration',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Join Finders Keepers with your verified campus email.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),

              AppTextField(
                label: 'Full Name',
                hintText: 'e.g. Jordan Smith',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: AppSpacing.m),

              AppTextField(
                label: 'Student ID Number',
                hintText: 'e.g. 24CS1092',
                controller: _studentIdController,
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: AppSpacing.m),

              AppTextField(
                label: 'Campus Email',
                hintText: 'e.g. jordan@campus.edu',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                errorText: _emailError,
              ),
              const SizedBox(height: AppSpacing.m),

              AppTextField(
                label: 'Password',
                hintText: 'Minimum 6 characters',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
              ),

              const SizedBox(height: AppSpacing.xxl),

              AppButton(
                label: 'Create Account',
                isLoading: isLoading,
                onPressed: isLoading ? null : _handleRegister,
              ),

              const SizedBox(height: AppSpacing.l),

              Center(
                child: TextButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
                  child: Text(
                    "Already have an account? Sign in",
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
