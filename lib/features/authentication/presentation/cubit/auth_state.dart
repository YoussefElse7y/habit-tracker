// File: features/authentication/presentation/cubit/auth_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Initial state - app just started
class AuthInitial extends AuthState {
  const AuthInitial();
}

// Loading states - something is happening
class AuthLoading extends AuthState {
  const AuthLoading();
}

// User is authenticated and logged in
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

// User is not authenticated (logged out or never logged in)
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

// Error occurred during auth operations
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// Registration was successful
class AuthRegistrationSuccess extends AuthState {
  final User user;
  final bool emailVerificationSent;

  const AuthRegistrationSuccess(this.user, {this.emailVerificationSent = false});

  @override
  List<Object?> get props => [user, emailVerificationSent];
}

// Password reset email was sent
class AuthPasswordResetEmailSent extends AuthState {
  final String email;

  const AuthPasswordResetEmailSent(this.email);

  @override
  List<Object?> get props => [email];
}

// Email verification was sent
class AuthEmailVerificationSent extends AuthState {
  const AuthEmailVerificationSent();
}

// Profile update was successful
class AuthProfileUpdateSuccess extends AuthState {
  final User updatedUser;

  const AuthProfileUpdateSuccess(this.updatedUser);

  @override
  List<Object?> get props => [updatedUser];
}

// Loading specific operations (more granular than AuthLoading)
class AuthLoginLoading extends AuthState {
  const AuthLoginLoading();
}

class AuthRegisterLoading extends AuthState {
  const AuthRegisterLoading();
}

class AuthGoogleLoading extends AuthState {
  const AuthGoogleLoading();
}

class AuthLogoutLoading extends AuthState {
  const AuthLogoutLoading();
}

// Specific error states for better error handling
class AuthLoginError extends AuthState {
  final String message;

  const AuthLoginError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthRegistrationError extends AuthState {
  final String message;

  const AuthRegistrationError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthNetworkError extends AuthState {
  final String message;

  const AuthNetworkError(this.message);

  @override
  List<Object?> get props => [message];
}

// Account deletion success
class AuthAccountDeletedSuccess extends AuthState {
  const AuthAccountDeletedSuccess();
}