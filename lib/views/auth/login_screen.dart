import 'package:chat_application/core/constants/app_paddings.dart';

import 'package:chat_application/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dependency_injection/app_provider.dart';
import '../../core/utils/app_utils.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends ConsumerWidget {
  LoginScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// watch auth state
    final authViewModel = ref.watch(authViewModelProvider);

    /// listen for auth changes
    ref.listen<AuthViewModel>(authViewModelProvider, (previous, next) {
      if (next.error != null) {
        AppUtils.showSnackBar(context, next.error!, isError: true);
      }
      if (next.isAuthenticated) {
        context.go('/chat-list');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppPaddings.defaultPadding,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomText(
                  text: "Welcome Back",
                  textAlign: TextAlign.center,
                  fontSize: 24,
                ),
                const SizedBox(height: 8),
                CustomText(
                  text: "Sign in to your account",
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 48),

                /// Email Field
                CustomTextField(
                  controller: _emailController,
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

                /// Password Field
                CustomTextField(
                  controller: _passwordController,
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
                const SizedBox(height: 24),

                /// Sign In Button
                CustomButton(
                  text: 'Sign In',
                  isLoading: authViewModel.isLoading,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ref
                          .read(authViewModelProvider)
                          .signIn(
                            _emailController.text.trim(),
                            _passwordController.text,
                          );
                    }
                  },
                ),
                const SizedBox(height: 16),

                /// Navigate to Register
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
