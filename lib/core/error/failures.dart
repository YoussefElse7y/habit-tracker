
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
  const ServerFailure(String message) : super(message);
}

/// Failure that occurs when there's a connection error
class ConnectionFailure extends Failure {
  const ConnectionFailure(String message) : super(message);
}

/// Failure that occurs when there's a cache error
class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

/// Failure that occurs when there's an authentication error
class AuthFailure extends Failure {
  const AuthFailure(String message) : super(message);
}

/// Failure that occurs when there's a validation error
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

/// Failure that occurs when there's a permission error
class PermissionFailure extends Failure {
  const PermissionFailure(String message) : super(message);
}

/// Failure that occurs when there's a not found error
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message);
}

/// Failure that occurs when there's a timeout error
class TimeoutFailure extends Failure {
  const TimeoutFailure(String message) : super(message);
}

/// Failure that occurs when there's an unknown error
class UnknownFailure extends Failure {
  const UnknownFailure(String message) : super(message);
}