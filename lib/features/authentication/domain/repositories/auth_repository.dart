
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  // Register new user with email and password
  Future<Either<Failure, User>> registerWithEmail({
    required String email,
    required String password,
    required String name,
  });

  // Login existing user with email and password
  Future<Either<Failure, User>> loginWithEmail({
    required String email,
    required String password,
  });

  // Login with Google account
  Future<Either<Failure, User>> loginWithGoogle();

  // Get currently logged in user (if any)
  Future<Either<Failure, User?>> getCurrentUser();

  // Logout current user
  Future<Either<Failure, void>> logout();

  // Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  // Send email verification
  Future<Either<Failure, void>> sendEmailVerification();

  // Update user profile
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? profileImageUrl,
  });

  // Delete user account
  Future<Either<Failure, void>> deleteAccount();

  // Check if user is logged in
  Future<bool> isLoggedIn();

  // Stream of authentication state changes
  Stream<User?> get authStateChanges;
}