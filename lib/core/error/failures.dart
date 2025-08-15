import 'package:equatable/equatable.dart';

/// Base failure class that all other failures extend
/// This follows the Result pattern for error handling
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Failure that occurs when there's a server error
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Failure that occurs when there's a connection error
class ConnectionFailure extends Failure {
  const ConnectionFailure(super.message);
}

/// Failure that occurs when there's a cache error
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Failure that occurs when there's an authentication error
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Failure that occurs when there's a validation error
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Failure that occurs when there's a permission error
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

/// Failure that occurs when there's a not found error
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Failure that occurs when there's a timeout error
class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}

/// Failure that occurs when there's an unknown error
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
