
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

// When server/API calls fail
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

// When there's no internet connection
class ConnectionFailure extends Failure {
  const ConnectionFailure(super.message);
}

// When local database operations fail
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

// When user input is invalid
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

// When user is not authenticated
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}