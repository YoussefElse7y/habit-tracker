// File: core/utils/validators.dart

import 'package:flutter/material.dart';

class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  /// Validates email address format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Remove whitespace
    value = value.trim();

    // Check minimum length
    if (value.length < 5) {
      return 'Email is too short';
    }

    // Check maximum length
    if (value.length > 254) {
      return 'Email is too long';
    }

    // Email regex pattern (RFC 5322 compliant)
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates password with customizable requirements
  static String? validatePassword(
    String? value, {
    int minLength = 6,
    int maxLength = 128,
    bool requireUppercase = false,
    bool requireLowercase = false,
    bool requireNumbers = false,
    bool requireSpecialChars = false,
  }) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    if (value.length > maxLength) {
      return 'Password cannot exceed $maxLength characters';
    }

    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (requireNumbers && !value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    if (requireSpecialChars && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  /// Validates that two passwords match
  static String? validatePasswordConfirmation(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validates name/username
  static String? validateName(
    String? value, {
    int minLength = 2,
    int maxLength = 50,
    bool allowNumbers = false,
    bool allowSpecialChars = false,
  }) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    // Remove leading/trailing whitespace
    value = value.trim();

    if (value.length < minLength) {
      return 'Name must be at least $minLength characters';
    }

    if (value.length > maxLength) {
      return 'Name cannot exceed $maxLength characters';
    }

    // Check for valid characters
    String pattern = r'^[a-zA-Z\s';
    if (allowNumbers) pattern += r'0-9';
    if (allowSpecialChars) pattern += r'._-';
    pattern += r']+$';

    final nameRegex = RegExp(pattern);
    if (!nameRegex.hasMatch(value)) {
      String allowedChars = 'letters and spaces';
      if (allowNumbers) allowedChars += ', numbers';
      if (allowSpecialChars) allowedChars += ', periods, underscores, and hyphens';
      return 'Name can only contain $allowedChars';
    }

    // Check for multiple consecutive spaces
    if (value.contains(RegExp(r'\s{2,}'))) {
      return 'Name cannot contain multiple consecutive spaces';
    }

    return null;
  }

  /// Validates phone number
  static String? validatePhoneNumber(String? value, {bool isRequired = true}) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'Phone number is required' : null;
    }

    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (digitsOnly.length > 15) {
      return 'Phone number cannot exceed 15 digits';
    }

    return null;
  }

  /// Validates required field
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Validates URL format
  static String? validateUrl(String? value, {bool isRequired = true}) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'URL is required' : null;
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  /// Validates numeric input
  static String? validateNumber(
    String? value, {
    bool isRequired = true,
    double? min,
    double? max,
    bool allowDecimals = true,
  }) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'This field is required' : null;
    }

    final numericValue = allowDecimals
        ? double.tryParse(value)
        : int.tryParse(value)?.toDouble();

    if (numericValue == null) {
      return allowDecimals
          ? 'Please enter a valid number'
          : 'Please enter a valid whole number';
    }

    if (min != null && numericValue < min) {
      return 'Value must be at least $min';
    }

    if (max != null && numericValue > max) {
      return 'Value cannot exceed $max';
    }

    return null;
  }

  /// Get password strength (0-4)
  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Length check
    if (password.length >= 8) strength++;

    // Uppercase check
    if (password.contains(RegExp(r'[A-Z]'))) strength++;

    // Lowercase check
    if (password.contains(RegExp(r'[a-z]'))) strength++;

    // Number check
    if (password.contains(RegExp(r'[0-9]'))) strength++;

    // Special character check
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    return strength > 4 ? 4 : strength;
  }

  /// Get password strength description
  static String getPasswordStrengthDescription(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Unknown';
    }
  }

  /// Get password strength color
  static Color getPasswordStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}