// File: core/usecases/usecase.dart

import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Base use case class that defines the contract for all use cases
/// This follows the Clean Architecture pattern and provides a consistent interface
abstract class UseCase<Type, Params> {
  /// Execute the use case with the given parameters
  /// Returns Either<Failure, Type> where Type is the success result
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case that doesn't require parameters
abstract class NoParamsUseCase<Type> {
  /// Execute the use case without parameters
  /// Returns Either<Failure, Type> where Type is the success result
  Future<Either<Failure, Type>> call();
}