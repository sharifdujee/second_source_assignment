import 'package:chat_application/core/constants/app_color.dart';
import 'package:chat_application/core/constants/app_paddings.dart';
import 'package:chat_application/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/app_utils.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../core/dependency_injection/app_provider.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    /// check user already login or not
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.error != null) {
        AppUtils.showSnackBar(context, next.error!, isError: true);
      }
      if (next.isAuthenticated) {
        context.go('/chat-list');
      }
    });

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    void signUp() {
      if (formKey.currentState!.validate()) {
        ref
            .read(authViewModelProvider.notifier)
            .signUp(
              emailController.text.trim(),
              passwordController.text,
              nameController.text.trim(),
            );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: Padding(
          padding: AppPaddings.defaultPadding,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomText(
                    text: "Create Account",
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 8),
                  CustomText(
                    text: "Sign up to get started",
                    fontSize: 16,
                    color: AppColors.greySix,
                  ),
                  const SizedBox(height: 32),

                  /// Full Name
                  CustomTextField(
                    controller: nameController,
                    hintText: 'Full Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      if (!AppUtils.isValidUsername(value)) {
                        return 'Name must be 3–16 characters (letters, numbers, underscore)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  /// Email
                  CustomTextField(
                    controller: emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!AppUtils.isValidEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  /// Password
                  CustomTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (!AppUtils.isValidPassword(value)) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  /// Confirm Password
                  CustomTextField(
                    controller: confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  /// Sign Up Button
                  CustomButton(
                    text: 'Sign Up',
                    isLoading: authState.isLoading,
                    onPressed: signUp,
                  ),
                  const SizedBox(height: 16),

                  /// Sign In Link
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Already have an account? Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
