
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.profileImageUrl,
    required super.createdAt,
    super.lastLoginAt,
    super.isEmailVerified,
  });

  // Convert from Firebase User to UserModel
  factory UserModel.fromFirebaseUser(dynamic firebaseUser, {String? displayName}) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: displayName ?? firebaseUser.displayName ?? 'User',
      profileImageUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: firebaseUser.metadata.lastSignInTime,
      isEmailVerified: firebaseUser.emailVerified ?? false,
    );
  }

  // Convert from Firestore document to UserModel
  factory UserModel.fromFirestore(Map<String, dynamic> doc) {
    return UserModel(
      id: doc['id'] ?? '',
      email: doc['email'] ?? '',
      name: doc['name'] ?? '',
      profileImageUrl: doc['profileImageUrl'],
      createdAt: _parseDateTime(doc['createdAt']),
      lastLoginAt: _parseDateTime(doc['lastLoginAt']),
      isEmailVerified: doc['isEmailVerified'] ?? false,
    );
  }

  // Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isEmailVerified': isEmailVerified,
    };
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isEmailVerified': isEmailVerified,
    };
  }

  // Create UserModel from JSON (local storage)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      createdAt: _parseDateTime(json['createdAt']),
      lastLoginAt: _parseDateTime(json['lastLoginAt']),
      isEmailVerified: json['isEmailVerified'] ?? false,
    );
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  // Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    if (dateValue is DateTime) {
      return dateValue;
    }
    
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    // Handle Firestore Timestamp
    if (dateValue.runtimeType.toString().contains('Timestamp')) {
      return dateValue.toDate();
    }
    
    return DateTime.now();
  }
}