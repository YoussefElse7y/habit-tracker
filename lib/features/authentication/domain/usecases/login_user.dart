
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUser implements UseCase<User, LoginParams> {
  final AuthRepository repository;

  LoginUser(this.repository);

  @override
  Future<Either<Failure, User>> call(LoginParams params) async {
    // Input validation
    if (params.email.isEmpty || params.password.isEmpty) {
      return const Left(ValidationFailure('Email and password cannot be empty'));
    }

    if (!_isValidEmail(params.email)) {
      return const Left(ValidationFailure('Please enter a valid email address'));
    }

    if (params.password.length < 6) {
      return const Left(ValidationFailure('Password must be at least 6 characters'));
    }

    // Delegate to repository for actual login
    return await repository.loginWithEmail(
      email: params.email.trim().toLowerCase(),
      password: params.password,
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
}

// Parameters class for login use case
class LoginParams {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });
}