// File: features/authentication/presentation/pages/register_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_login_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Form and controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // UI state
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  bool _autoValidate = false;
  
  // Password strength tracking
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = AppColors.error;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: _handleAuthStateChanges,
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildRegistrationForm(),
                  const SizedBox(height: 24),
                  _buildSignUpButton(state),
                  const SizedBox(height: 32),
                  _buildDivider(),
                  const SizedBox(height: 24),
                  _buildSocialLogin(state),
                  const SizedBox(height: 32),
                  _buildLoginPrompt(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Handles authentication state changes for UI feedback
  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is AuthRegistrationError) {
      CustomSnackBar.showError(
        context: context,
        message: state.message,
      );
    } else if (state is AuthError) {
      CustomSnackBar.showError(
        context: context,
        message: state.message,
      );
    } else if (state is AuthRegistrationSuccess) {
      CustomSnackBar.showSuccess(
        context: context,
        message: state.emailVerificationSent
            ? 'Account created! Please check your email for verification.'
            : 'Account created successfully!',
      );
    }
  }

  /// Builds the header section with app branding
  Widget _buildHeader() {
    return Column(
      children: [
        // App Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.track_changes,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        
        // Welcome text
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign up to start your habit journey',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Builds the registration form
  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      autovalidateMode: _autoValidate 
          ? AutovalidateMode.onUserInteraction 
          : AutovalidateMode.disabled,
      child: Column(
        children: [
          // Full Name Field
          AuthTextField(
            controller: _nameController,
            label: 'Full Name',
            hintText: 'Enter your full name',
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
          
            prefixIcon: Icons.person_outlined,
            validator: _validateName,
          ),
          
          const SizedBox(height: 20),
          
          // Email Field
          AuthTextField(
            controller: _emailController,
            label: 'Email',
            hintText: 'Enter your email address',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.email_outlined,
            validator: Validators.validateEmail,
          ),
          
          const SizedBox(height: 20),
          
          // Password Field with Strength Indicator
          Column(
            children: [
              AuthTextField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Create a strong password',
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.lock_outlined,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                validator: _validatePassword,
              ),
              
              // Password Strength Indicator
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildPasswordStrengthIndicator(),
              ],
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Confirm Password Field
          AuthTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hintText: 'Confirm your password',
            obscureText: !_isConfirmPasswordVisible,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outlined,
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            validator: _validateConfirmPassword,
            onFieldSubmitted: (_) => _handleSignUp(),
          ),
          
          const SizedBox(height: 20),
          
          // Terms and Conditions
          _buildTermsAcceptance(),
        ],
      ),
    );
  }

  /// Builds the password strength indicator
  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: _passwordStrength,
                backgroundColor: AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _passwordStrengthText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _passwordStrengthColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Password must contain: 8+ characters, uppercase, lowercase, number',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  /// Builds terms and conditions acceptance
  Widget _buildTermsAcceptance() {
    return InkWell(
      onTap: () {
        setState(() {
          _acceptTerms = !_acceptTerms;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptTerms = value ?? false;
                  });
                },
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the sign up button with loading state
  Widget _buildSignUpButton(AuthState state) {
    final isLoading = state is AuthRegisterLoading;
    final isDisabled = isLoading || !_acceptTerms;
    
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isDisabled ? null : _handleSignUp,
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
                  Text(
                    'Creating Account...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// Builds the divider with "or" text
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.divider,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.divider,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  /// Builds social login options
  Widget _buildSocialLogin(AuthState state) {
    return SocialLoginButton(
      onPressed: state is AuthGoogleLoading ? null : _handleGoogleSignUp,
      isLoading: state is AuthGoogleLoading,
      provider: 'Google',
      icon: 'assets/images/google_logo.png',
      fallbackIcon: Icons.account_circle,
    );
  }

  /// Builds login prompt
  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign In',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // VALIDATION METHODS

  /// Validates name input
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Name cannot exceed 50 characters';
    }
    
    // Check if name contains only letters, spaces, and common characters
    final nameRegex = RegExp(r"^[a-zA-Z\s\-'\.]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name contains invalid characters';
    }
    
    return null;
  }

  /// Validates password input
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  /// Validates confirm password input
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // PASSWORD STRENGTH METHODS

  /// Updates password strength indicator
  void _updatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _passwordStrength = _calculatePasswordStrength(password);
      _updatePasswordStrengthText(_passwordStrength);
    });
  }

  /// Calculates password strength (0.0 to 1.0)
  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    
    double strength = 0.0;
    
    // Length check (0.25)
    if (password.length >= 8) strength += 0.25;
    
    // Uppercase check (0.25)
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    
    // Lowercase check (0.25)  
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.25;
    
    // Number check (0.25)
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    
    return strength;
  }

  /// Updates password strength text and color
  void _updatePasswordStrengthText(double strength) {
    if (strength == 0.0) {
      _passwordStrengthText = '';
      _passwordStrengthColor = AppColors.error;
    } else if (strength <= 0.25) {
      _passwordStrengthText = 'Weak';
      _passwordStrengthColor = AppColors.error;
    } else if (strength <= 0.5) {
      _passwordStrengthText = 'Fair';
      _passwordStrengthColor = AppColors.warning;
    } else if (strength <= 0.75) {
      _passwordStrengthText = 'Good';
      _passwordStrengthColor = AppColors.info;
    } else {
      _passwordStrengthText = 'Strong';
      _passwordStrengthColor = AppColors.success;
    }
  }

  // EVENT HANDLERS

  /// Handles sign up form submission
  void _handleSignUp() {
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Check terms acceptance first
    if (!_acceptTerms) {
      CustomSnackBar.showError(
        context: context,
        message: 'Please accept the Terms of Service and Privacy Policy',
      );
      return;
    }

    // Enable auto validation for better UX
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

    // Extract form data
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Trigger registration through AuthCubit
    context.read<AuthCubit>().registerWithEmail(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  /// Handles Google Sign-Up
  void _handleGoogleSignUp() {
    HapticFeedback.lightImpact();
    context.read<AuthCubit>().loginWithGoogle();
  }
}