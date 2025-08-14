// File: features/authentication/domain/usecases/register_user.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUser implements UseCase<User, RegisterParams> {
  final AuthRepository repository;

  RegisterUser(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) async {
    // Input validation
    final validationResult = _validateInput(params);
    if (validationResult != null) {
      return Left(ValidationFailure(validationResult));
    }

    // Delegate to repository for actual registration
    return await repository.registerWithEmail(
      email: params.email.trim().toLowerCase(),
      password: params.password,
      name: params.name.trim(),
    );
  }

  String? _validateInput(RegisterParams params) {
    // Check for empty fields
    if (params.email.isEmpty) {
      return 'Email cannot be empty';
    }
    if (params.password.isEmpty) {
      return 'Password cannot be empty';
    }
    if (params.name.isEmpty) {
      return 'Name cannot be empty';
    }

    // Email validation
    if (!_isValidEmail(params.email)) {
      return 'Please enter a valid email address';
    }

    // Password strength validation
    if (params.password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (!_hasUpperCase(params.password)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!_hasNumber(params.password)) {
      return 'Password must contain at least one number';
    }

    // Name validation
    if (params.name.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (params.name.length > 50) {
      return 'Name cannot exceed 50 characters';
    }

    // Confirm password validation
    if (params.password != params.confirmPassword) {
      return 'Passwords do not match';
    }

    return null; // All validations passed
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _hasUpperCase(String password) {
    return password.contains(RegExp(r'[A-Z]'));
  }

  bool _hasNumber(String password) {
    return password.contains(RegExp(r'[0-9]'));
  }
}

// Parameters class for register use case
class RegisterParams {
  final String email;
  final String password;
  final String confirmPassword;
  final String name;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.name,
  });
}