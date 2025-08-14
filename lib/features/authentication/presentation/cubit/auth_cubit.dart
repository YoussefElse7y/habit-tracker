// File: features/authentication/presentation/cubit/auth_cubit.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUser _loginUser;
  final RegisterUser _registerUser;
  final AuthRepository _authRepository;
  
  StreamSubscription<User?>? _authStateSubscription;

  AuthCubit({
    required LoginUser loginUser,
    required RegisterUser registerUser,
    required AuthRepository authRepository,
  })  : _loginUser = loginUser,
        _registerUser = registerUser,
        _authRepository = authRepository,
        super(const AuthInitial()) {
    // Start listening to auth state changes
    _startAuthStateListener();
    // Check if user is already logged in
    _checkInitialAuthState();
  }

  // Check if user is already authenticated when app starts
  Future<void> _checkInitialAuthState() async {
    emit(const AuthLoading());

    final result = await _authRepository.getCurrentUser();
    
    result.fold(
      (failure) {
        // No user or error getting user - user is unauthenticated
        emit(const AuthUnauthenticated());
      },
      (user) {
        if (user != null) {
          // User is logged in
          emit(AuthAuthenticated(user));
        } else {
          // No user logged in
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  // Listen to auth state changes (Firebase Auth stream)
  void _startAuthStateListener() {
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) {
        if (user != null) {
          // User logged in from external source (like deep links)
          emit(AuthAuthenticated(user));
        } else {
          // User logged out from external source
          if (state is! AuthLogoutLoading) {
            // Only emit unauthenticated if we're not in the middle of logout
            emit(const AuthUnauthenticated());
          }
        }
      },
      onError: (error) {
        emit(AuthError('Authentication stream error: ${error.toString()}'));
      },
    );
  }

  // LOGIN with email and password
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoginLoading());

    final result = await _loginUser(LoginParams(
      email: email,
      password: password,
    ));

    result.fold(
      (failure) {
        // Login failed
        emit(AuthLoginError(failure.message));
        
        // Auto-reset to unauthenticated after showing error
        Future.delayed(const Duration(seconds: 3), () {
          if (state is AuthLoginError) {
            emit(const AuthUnauthenticated());
          }
        });
      },
      (user) {
        // Login successful
        emit(AuthAuthenticated(user));
      },
    );
  }

  // REGISTER with email and password
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String confirmPassword,
    required String name,
  }) async {
    emit(const AuthRegisterLoading());

    final result = await _registerUser(RegisterParams(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      name: name,
    ));

    result.fold(
      (failure) {
        // Registration failed
        emit(AuthRegistrationError(failure.message));
        
        // Auto-reset to unauthenticated after showing error
        Future.delayed(const Duration(seconds: 3), () {
          if (state is AuthRegistrationError) {
            emit(const AuthUnauthenticated());
          }
        });
      },
      (user) {
        // Registration successful
        emit(AuthRegistrationSuccess(user, emailVerificationSent: true));
        
        // Auto-transition to authenticated after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (state is AuthRegistrationSuccess) {
            emit(AuthAuthenticated(user));
          }
        });
      },
    );
  }

  // LOGIN with Google
  Future<void> loginWithGoogle() async {
    emit(const AuthGoogleLoading());

    final result = await _authRepository.loginWithGoogle();

    result.fold(
      (failure) {
        emit(AuthError(failure.message));
        
        Future.delayed(const Duration(seconds: 3), () {
          if (state is AuthError) {
            emit(const AuthUnauthenticated());
          }
        });
      },
      (user) {
        emit(AuthAuthenticated(user));
      },
    );
  }

  // LOGOUT
  Future<void> logout() async {
    emit(const AuthLogoutLoading());

    final result = await _authRepository.logout();

    result.fold(
      (failure) {
        // Even if logout fails remotely, clear local state
        emit(const AuthUnauthenticated());
      },
      (_) {
        emit(const AuthUnauthenticated());
      },
    );
  }

  // SEND PASSWORD RESET EMAIL
  Future<void> sendPasswordResetEmail(String email) async {
    emit(const AuthLoading());

    final result = await _authRepository.sendPasswordResetEmail(email);

    result.fold(
      (failure) {
        emit(AuthError(failure.message));
        
        // Reset to unauthenticated after showing error
        Future.delayed(const Duration(seconds: 3), () {
          if (state is AuthError) {
            emit(const AuthUnauthenticated());
          }
        });
      },
      (_) {
        emit(AuthPasswordResetEmailSent(email));
        
        // Reset to unauthenticated after showing success message
        Future.delayed(const Duration(seconds: 3), () {
          if (state is AuthPasswordResetEmailSent) {
            emit(const AuthUnauthenticated());
          }
        });
      },
    );
  }

  // SEND EMAIL VERIFICATION
  Future<void> sendEmailVerification() async {
    emit(const AuthLoading());

    final result = await _authRepository.sendEmailVerification();

    result.fold(
      (failure) {
        emit(AuthError(failure.message));
      },
      (_) {
        emit(const AuthEmailVerificationSent());
        
        // Return to current user state after showing success
        Future.delayed(const Duration(seconds: 2), () async {
          if (state is AuthEmailVerificationSent) {
            final userResult = await _authRepository.getCurrentUser();
            userResult.fold(
              (_) => emit(const AuthUnauthenticated()),
              (user) => user != null 
                ? emit(AuthAuthenticated(user))
                : emit(const AuthUnauthenticated()),
            );
          }
        });
      },
    );
  }

  // UPDATE PROFILE
  Future<void> updateProfile({
    String? name,
    String? profileImageUrl,
  }) async {
    // Don't show loading for profile updates to keep UI smooth
    final result = await _authRepository.updateProfile(
      name: name,
      profileImageUrl: profileImageUrl,
    );

    result.fold(
      (failure) {
        emit(AuthError(failure.message));
        
        // Return to previous authenticated state after error
        Future.delayed(const Duration(seconds: 2), () async {
          if (state is AuthError) {
            final userResult = await _authRepository.getCurrentUser();
            userResult.fold(
              (_) => emit(const AuthUnauthenticated()),
              (user) => user != null 
                ? emit(AuthAuthenticated(user))
                : emit(const AuthUnauthenticated()),
            );
          }
        });
      },
      (updatedUser) {
        emit(AuthProfileUpdateSuccess(updatedUser));
        
        // Transition to authenticated with updated user
        Future.delayed(const Duration(seconds: 1), () {
          if (state is AuthProfileUpdateSuccess) {
            emit(AuthAuthenticated(updatedUser));
          }
        });
      },
    );
  }

  // DELETE ACCOUNT
  Future<void> deleteAccount() async {
    emit(const AuthLoading());

    final result = await _authRepository.deleteAccount();

    result.fold(
      (failure) {
        emit(AuthError(failure.message));
        
        // Return to authenticated state if deletion fails
        Future.delayed(const Duration(seconds: 3), () async {
          if (state is AuthError) {
            final userResult = await _authRepository.getCurrentUser();
            userResult.fold(
              (_) => emit(const AuthUnauthenticated()),
              (user) => user != null 
                ? emit(AuthAuthenticated(user))
                : emit(const AuthUnauthenticated()),
            );
          }
        });
      },
      (_) {
        emit(const AuthAccountDeletedSuccess());
        
        // Transition to unauthenticated after showing success
        Future.delayed(const Duration(seconds: 2), () {
          if (state is AuthAccountDeletedSuccess) {
            emit(const AuthUnauthenticated());
          }
        });
      },
    );
  }

  // UTILITY METHODS

  // Check if user is currently authenticated
  bool get isAuthenticated => state is AuthAuthenticated;

  // Get current user (null if not authenticated)
  User? get currentUser {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.user;
    }
    return null;
  }

  // Check if any operation is in progress
  bool get isLoading {
    return state is AuthLoading ||
           state is AuthLoginLoading ||
           state is AuthRegisterLoading ||
           state is AuthGoogleLoading ||
           state is AuthLogoutLoading;
  }

  // Get current error message (null if no error)
  String? get errorMessage {
    final currentState = state;
    if (currentState is AuthError) {
      return currentState.message;
    }
    if (currentState is AuthLoginError) {
      return currentState.message;
    }
    if (currentState is AuthRegistrationError) {
      return currentState.message;
    }
    return null;
  }

  // CLEANUP
  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}