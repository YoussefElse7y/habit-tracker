// File: features/authentication/domain/usecases/send_password_reset_email.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class SendPasswordResetEmail implements UseCase<void, String> {
  final AuthRepository repository;

  SendPasswordResetEmail(this.repository);

  @override
  Future<Either<Failure, void>> call(String email) {
    return repository.sendPasswordResetEmail(email);
  }
}
