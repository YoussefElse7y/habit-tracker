
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isEmailVerified;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.isEmailVerified = false,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        profileImageUrl,
        createdAt,
        lastLoginAt,
        isEmailVerified,
      ];
}