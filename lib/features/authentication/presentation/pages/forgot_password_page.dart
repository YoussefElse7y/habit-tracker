// File: features/authentication/presentation/pages/forgot_password_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _autoValidate = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Reset Password',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: _handleAuthStateChanges,
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildResetForm(),
                  const SizedBox(height: 32),
                  _buildResetButton(state),
                  const SizedBox(height: 24),
                  _buildBackToLoginButton(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Handles authentication state changes
  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is AuthPasswordResetEmailSent) {
      CustomSnackBar.showSuccess(
        context: context,
        message: 'Password reset email sent to ${state.email}',
      );
      
      // Navigate back after showing success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else if (state is AuthError) {
      CustomSnackBar.showError(
        context: context,
        message: state.message,
      );
    }
  }

  /// Builds the header section
  Widget _buildHeader() {
    return Column(
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.lock_reset,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Title
        Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        // Description
        Text(
          'Don\'t worry! Enter your email address and we\'ll send you a link to reset your password.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds the reset form
  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      autovalidateMode: _autoValidate 
          ? AutovalidateMode.onUserInteraction 
          : AutovalidateMode.disabled,
      child: AuthTextField(
        controller: _emailController,
        label: 'Email Address',
        hintText: 'Enter your email address',
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        prefixIcon: Icons.email_outlined,
        validator: Validators.validateEmail,
        onFieldSubmitted: (_) => _handleResetPassword(),
      ),
    );
  }

  /// Builds the reset password button
  Widget _buildResetButton(AuthState state) {
    final isLoading = state is AuthLoading;
    
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleResetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
          elevation: 2,
          shadowColor: AppColors.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sending...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const Text(
                'Send Reset Link',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// Builds the back to login button
  Widget _buildBackToLoginButton() {
    return TextButton.icon(
      onPressed: () => Navigator.of(context).pop(),
      icon: Icon(
        Icons.arrow_back,
        size: 18,
        color: AppColors.textSecondary,
      ),
      label: Text(
        'Back to Login',
        style: TextStyle(
          fontSize: 16,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Handles password reset
  void _handleResetPassword() {
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Enable auto validation
    if (!_autoValidate) {
      setState(() {
        _autoValidate = true;
      });
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.selectionClick();
      return;
    }

    // Get email
    final email = _emailController.text.trim().toLowerCase();

    // Send reset email
    context.read<AuthCubit>().sendPasswordResetEmail(email);
  }
}