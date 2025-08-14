import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../authentication/domain/entities/user.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImagePicker _imagePicker;

  ProfileCubit({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    ImagePicker? imagePicker,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _imagePicker = imagePicker ?? ImagePicker(),
        super(ProfileInitial());

  Future<void> loadUserProfile() async {
    try {
      emit(ProfileLoading());
      
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        emit(const ProfileError(message: 'No user logged in'));
        return;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final user = User(
          id: currentUser.uid,
          email: currentUser.email ?? '',
          name: data['name'] ?? currentUser.displayName ?? '',
          profileImageUrl: data['profileImageUrl'] ?? currentUser.photoURL,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            data['createdAt']?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
          ),
          lastLoginAt: data['lastLoginAt'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(data['lastLoginAt'].millisecondsSinceEpoch)
              : null,
          isEmailVerified: currentUser.emailVerified,
        );
        emit(ProfileLoaded(user: user));
      } else {
        // Create user document if it doesn't exist
        final user = User(
          id: currentUser.uid,
          email: currentUser.email ?? '',
          name: currentUser.displayName ?? '',
          profileImageUrl: currentUser.photoURL,
          createdAt: DateTime.now(),
          isEmailVerified: currentUser.emailVerified,
        );
        
        await _createUserDocument(user);
        emit(ProfileLoaded(user: user));
      }
    } catch (e) {
      emit(ProfileError(message: 'Failed to load profile: $e'));
    }
  }

  Future<void> pickAndUploadImage({required ImageSource source}) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        emit(const ProfileError(message: 'No user logged in'));
        return;
      }

      emit(ProfileImageUploading());

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        // User cancelled the picker
        await loadUserProfile(); // Return to previous state
        return;
      }

      final file = File(pickedFile.path);
      
      // Upload to Firebase Storage
      final storageRef = _storage
          .ref()
          .child('profile_images')
          .child('${currentUser.uid}.jpg');

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update user document in Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({'profileImageUrl': downloadUrl});

      // Update Firebase Auth profile
      await currentUser.updatePhotoURL(downloadUrl);

      // Load updated profile
      await loadUserProfile();
      
      if (state is ProfileLoaded) {
        emit(ProfileImageUploaded(
          imageUrl: downloadUrl,
          updatedUser: (state as ProfileLoaded).user,
        ));
      }
    } catch (e) {
      emit(ProfileError(message: 'Failed to upload image: $e'));
    }
  }

  Future<void> updateUserName(String newName) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        emit(const ProfileError(message: 'No user logged in'));
        return;
      }

      emit(ProfileLoading());

      // Update Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({'name': newName});

      // Update Firebase Auth
      await currentUser.updateDisplayName(newName);

      // Reload profile
      await loadUserProfile();
      
      if (state is ProfileLoaded) {
        emit(ProfileUpdateSuccess(updatedUser: (state as ProfileLoaded).user));
      }
    } catch (e) {
      emit(ProfileError(message: 'Failed to update name: $e'));
    }
  }

  Future<void> _createUserDocument(User user) async {
    await _firestore.collection('users').doc(user.id).set({
      'name': user.name,
      'email': user.email,
      'profileImageUrl': user.profileImageUrl,
      'createdAt': Timestamp.fromDate(user.createdAt),
      'isEmailVerified': user.isEmailVerified,
    });
  }
}