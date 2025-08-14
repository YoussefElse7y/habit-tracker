// File: features/authentication/presentation/pages/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habit_tracker_app/features/authentication/domain/entities/user.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'login_page.dart';
import '../../../habits/presentation/pages/home_page.dart'; // We'll create this later

/// AuthWrapper is the root navigation controller that determines
/// which screen to show based on the current authentication state.
///
/// This widget listens to AuthCubit state changes and automatically
/// navigates between authenticated and unauthenticated flows.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      // Listen to state changes for side effects
      listener: (context, state) {
        _handleStateChanges(context, state);
      },

      // Build different UIs based on current state
      builder: (context, state) {
        return _buildScreen(context, state);
      },
    );
  }

  /// Handles side effects when auth state changes
  void _handleStateChanges(BuildContext context, AuthState state) {
    // Show snackbars for success/error states
    if (state is AuthRegistrationSuccess) {
      _showSnackBar(
        context,
        'Registration successful! ${state.emailVerificationSent ? 'Please check your email for verification.' : ''}',
        isSuccess: true,
      );
    } else if (state is AuthPasswordResetEmailSent) {
      _showSnackBar(
        context,
        'Password reset email sent to ${state.email}',
        isSuccess: true,
      );
    } else if (state is AuthEmailVerificationSent) {
      _showSnackBar(
        context,
        'Email verification sent! Please check your inbox.',
        isSuccess: true,
      );
    } else if (state is AuthProfileUpdateSuccess) {
      _showSnackBar(
        context,
        'Profile updated successfully!',
        isSuccess: true,
      );
    } else if (state is AuthAccountDeletedSuccess) {
      _showSnackBar(
        context,
        'Account deleted successfully. We\'re sorry to see you go!',
        isSuccess: true,
      );
    } else if (state is AuthError) {
      _showSnackBar(
        context,
        state.message,
        isSuccess: false,
      );
    } else if (state is AuthLoginError) {
      _showSnackBar(
        context,
        state.message,
        isSuccess: false,
      );
    } else if (state is AuthRegistrationError) {
      _showSnackBar(
        context,
        state.message,
        isSuccess: false,
      );
    } else if (state is AuthNetworkError) {
      _showSnackBar(
        context,
        'Network error: ${state.message}',
        isSuccess: false,
      );
    }
  }

  /// Builds the appropriate screen based on current auth state
  Widget _buildScreen(BuildContext context, AuthState state) {
    // Show loading screen during initial authentication check
    if (state is AuthInitial || state is AuthLoading) {
      return const _LoadingScreen();
    }

    // Show authenticated app if user is logged in
    if (state is AuthAuthenticated) {
      return HomePage(); // Main app screen
    }

    // Show login/register flow for all unauthenticated states
    // This includes: AuthUnauthenticated, AuthLoginError, AuthRegistrationError, etc.
    return const LoginPage();
  }

  /// Shows a snackbar with success or error styling
  void _showSnackBar(BuildContext context, String message,
      {required bool isSuccess}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: Duration(seconds: isSuccess ? 3 : 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

/// Loading screen shown during authentication state initialization
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Icon(
              Icons.track_changes,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 24),

            // App name
            Text(
              'Habit Tracker',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 48),

            // Loading indicator
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),

            // Loading text
            Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alternative AuthWrapper implementation with more explicit routing
/// This version could be used if you prefer manual route management
class AuthWrapperWithRouting extends StatefulWidget {
  const AuthWrapperWithRouting({super.key});

  @override
  State<AuthWrapperWithRouting> createState() => _AuthWrapperWithRoutingState();
}

class _AuthWrapperWithRoutingState extends State<AuthWrapperWithRouting> {
  late final GlobalKey<NavigatorState> _navigatorKey;

  @override
  void initState() {
    super.initState();
    _navigatorKey = GlobalKey<NavigatorState>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // Handle navigation based on state changes
        if (state is AuthAuthenticated) {
          _navigateToHome();
        } else if (state is AuthUnauthenticated ||
            state is AuthLoginError ||
            state is AuthRegistrationError) {
          _navigateToLogin();
        }
      },
      child: Navigator(
        key: _navigatorKey,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (_) => const _LoadingScreen(),
                settings: settings,
              );
            case '/login':
              return MaterialPageRoute(
                builder: (_) => const LoginPage(),
                settings: settings,
              );
            case '/home':
              return MaterialPageRoute(
                builder: (_) => HomePage(),
                settings: settings,
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const LoginPage(),
                settings: settings,
              );
          }
        },
      ),
    );
  }

  void _navigateToLogin() {
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  void _navigateToHome() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/home',
        arguments: authState.user,
        (route) => false,
      );
    }
  }
}
