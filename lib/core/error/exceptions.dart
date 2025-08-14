
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);
  
  @override
  String toString() => 'AppException: $message';
}

// Thrown when server returns an error (4xx, 5xx status codes)
class ServerException extends AppException {
  const ServerException(super.message);
  
  @override
  String toString() => 'ServerException: $message';
}

// Thrown when there's no internet connection
class ConnectionException extends AppException {
  const ConnectionException(super.message);
  
  @override
  String toString() => 'ConnectionException: $message';
}

// Thrown when local storage operations fail
class CacheException extends AppException {
  const CacheException(super.message);
  
  @override
  String toString() => 'CacheException: $message';
}

// Thrown when user input is invalid
class ValidationException extends AppException {
  const ValidationException(super.message);
  
  @override
  String toString() => 'ValidationException: $message';
}

// Thrown when authentication fails
class AuthException extends AppException {
  const AuthException(super.message);
  
  @override
  String toString() => 'AuthException: $message';
}