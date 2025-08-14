// File: features/authentication/domain/usecases/update_profile.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileParams {
  final String? name;
  final String? profileImageUrl;

  UpdateProfileParams({this.name, this.profileImageUrl});
}

class UpdateProfile implements UseCase<User, UpdateProfileParams> {
  final AuthRepository repository;

  UpdateProfile(this.repository);

  @override
  Future<Either<Failure, User>> call(UpdateProfileParams params) {
    return repository.updateProfile(
      name: params.name,
      profileImageUrl: params.profileImageUrl,
    );
  }
}
