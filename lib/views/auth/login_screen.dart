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
    /// create a provider for authModelProvider, the auth model provider is define inside viewModels
    final authViewModel = ref.watch(authViewModelProvider);

   /// initially check is user is already login navigate chat screen, for routing use go-router package
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
            /// form key is used for check the form validation.
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// custom text is define in constants directory inside core directory
                CustomText(text: "Welcome Back", textAlign: TextAlign.center,fontSize: 24,),

                const SizedBox(height: 8),
                CustomText(text: "Sign in to your account", fontSize: 16,color: Colors.grey[600],),

                const SizedBox(height: 48),
                /// text field for enter user email here check the regular expression
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Sign In',
                  isLoading: authViewModel.isLoading,
                  onPressed: () {
                    /// here check the form validation email and password is empty or not
                    if (_formKey.currentState!.validate()) {
                      ref.read(authViewModelProvider).signIn(
                        _emailController.text.trim(),
                        _passwordController.text,
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
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

