import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String name,
  });

  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> loginWithGoogle();

  Future<UserModel?> getCurrentUser();

  Future<void> logout();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendEmailVerification();

  Future<UserModel> updateProfile({
    String? name,
    String? profileImageUrl,
  });

  Future<void> deleteAccount();

  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.googleSignIn,
  });

  @override
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create Firebase Auth account
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException('Failed to create user account');
      }

      // Update display name
      await firebaseUser.updateDisplayName(name);

      // Create user document in Firestore
      final userModel =
          UserModel.fromFirebaseUser(firebaseUser, displayName: name);
      await _saveUserToFirestore(userModel);

      // Send email verification
      await firebaseUser.sendEmailVerification();

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException('Login failed - no user returned');
      }

      // Update last login time in Firestore
      final userModel = UserModel.fromFirebaseUser(firebaseUser);
      await _updateLastLoginTime(userModel.id);

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    try {
      // Sign out any existing Google Sign-In session
      await googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        throw const AuthException('Google sign-in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential =
          await firebaseAuth.signInWithCredential(credential);

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthException('Google sign-in failed - no user returned');
      }

      // Create or update user in Firestore
      final userModel = UserModel.fromFirebaseUser(firebaseUser);
      await _saveUserToFirestore(userModel);

      return userModel;
    } catch (e) {
      throw AuthException('Google sign-in failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      return UserModel.fromFirebaseUser(firebaseUser);
    } catch (e) {
      throw AuthException('Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await Future.wait([
        firebaseAuth.signOut(),
        googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Logout failed: ${e.toString()}');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(
          'Failed to send password reset email: ${e.toString()}');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No user is currently signed in');
      }
      await user.sendEmailVerification();
    } catch (e) {
      throw AuthException('Failed to send email verification: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    String? profileImageUrl,
  }) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No user is currently signed in');
      }

      // Update Firebase Auth profile
      await user.updateDisplayName(name);
      await user.updatePhotoURL(profileImageUrl);

      // Update Firestore document
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({
        if (name != null) 'name': name,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reload to get updated data
      await user.reload();
      final updatedUser = firebaseAuth.currentUser!;

      return UserModel.fromFirebaseUser(updatedUser);
    } catch (e) {
      throw AuthException('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No user is currently signed in');
      }

      final userId = user.uid;

      // Delete user document from Firestore
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .delete();

      // Delete user's habits
      final habitsQuery = await firestore
          .collection(AppConstants.habitsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = firestore.batch();
      for (var doc in habitsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete Firebase Auth account
      await user.delete();
    } catch (e) {
      throw AuthException('Failed to delete account: ${e.toString()}');
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null
          ? UserModel.fromFirebaseUser(firebaseUser)
          : null;
    });
  }

  // Helper method to save user to Firestore
  Future<void> _saveUserToFirestore(UserModel user) async {
    await firestore
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  // Helper method to update last login time
  Future<void> _updateLastLoginTime(String userId) async {
    await firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  // Helper method to handle Firebase Auth exceptions
  AuthException _handleFirebaseAuthException(
      firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthException('No user found with this email address');
      case 'wrong-password':
        return const AuthException('Incorrect password');
      case 'email-already-in-use':
        return const AuthException('An account already exists with this email');
      case 'weak-password':
        return const AuthException('Password is too weak');
      case 'invalid-email':
        return const AuthException('Invalid email address');
      case 'user-disabled':
        return const AuthException('This account has been disabled');
      case 'too-many-requests':
        return const AuthException('Too many attempts. Please try again later');
      default:
        return AuthException('Authentication error: ${e.message}');
    }
  }
}
