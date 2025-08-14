// File: features/authentication/data/datasources/auth_local_datasource.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  /// Cache user data locally for offline access
  Future<void> cacheUser(UserModel user);
  
  /// Get cached user data
  Future<UserModel?> getCachedUser();
  
  /// Cache user authentication token
  Future<void> cacheAuthToken(String token);
  
  /// Get cached authentication token
  Future<String?> getCachedAuthToken();
  
  /// Clear all authentication data (logout)
  Future<void> clearAllAuthData();
  
  /// Check if user data is cached
  Future<bool> hasUserData();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      // Convert user model to JSON string
      final userJson = json.encode(user.toJson());
      
      // Store in SharedPreferences
      final success = await sharedPreferences.setString(
        AppConstants.userDataKey, 
        userJson,
      );

      if (!success) {
        throw const CacheException('Failed to cache user data');
      }

      // Also cache basic user info separately for quick access
      await Future.wait([
        sharedPreferences.setString('cached_user_id', user.id),
        sharedPreferences.setString('cached_user_email', user.email),
        sharedPreferences.setString('cached_user_name', user.name),
      ]);

    } catch (e) {
      throw CacheException('Failed to cache user: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      // Get user JSON from SharedPreferences
      final userJsonString = sharedPreferences.getString(AppConstants.userDataKey);
      
      if (userJsonString == null || userJsonString.isEmpty) {
        return null; // No cached user
      }

      // Parse JSON and create UserModel
      final userJson = json.decode(userJsonString) as Map<String, dynamic>;
      return UserModel.fromJson(userJson);

    } catch (e) {
      throw CacheException('Failed to get cached user: ${e.toString()}');
    }
  }

  @override
  Future<void> cacheAuthToken(String token) async {
    try {
      final success = await sharedPreferences.setString(
        AppConstants.userTokenKey,
        token,
      );

      if (!success) {
        throw const CacheException('Failed to cache auth token');
      }

      // Also store timestamp when token was cached
      await sharedPreferences.setInt(
        'token_cached_at',
        DateTime.now().millisecondsSinceEpoch,
      );

    } catch (e) {
      throw CacheException('Failed to cache auth token: ${e.toString()}');
    }
  }

  @override
  Future<String?> getCachedAuthToken() async {
    try {
      final token = sharedPreferences.getString(AppConstants.userTokenKey);
      
      if (token == null) return null;

      // Check if token is expired (optional - depends on your token strategy)
      final cachedAt = sharedPreferences.getInt('token_cached_at');
      if (cachedAt != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(cachedAt);
        final hoursSinceCache = DateTime.now().difference(cacheTime).inHours;
        
        // If token is older than 24 hours, consider it expired
        if (hoursSinceCache > 24) {
          await _removeAuthToken();
          return null;
        }
      }

      return token;
    } catch (e) {
      throw CacheException('Failed to get cached auth token: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAllAuthData() async {
    try {
      final futures = <Future>[];

      // Remove all auth-related data
      final keysToRemove = [
        AppConstants.userDataKey,
        AppConstants.userTokenKey,
        'cached_user_id',
        'cached_user_email', 
        'cached_user_name',
        'token_cached_at',
      ];

      for (String key in keysToRemove) {
        futures.add(sharedPreferences.remove(key));
      }

      // Wait for all removals to complete
      await Future.wait(futures);

    } catch (e) {
      throw CacheException('Failed to clear auth data: ${e.toString()}');
    }
  }

  @override
  Future<bool> hasUserData() async {
    try {
      final userJson = sharedPreferences.getString(AppConstants.userDataKey);
      return userJson != null && userJson.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Private helper methods

  Future<void> _removeAuthToken() async {
    await Future.wait([
      sharedPreferences.remove(AppConstants.userTokenKey),
      sharedPreferences.remove('token_cached_at'),
    ]);
  }

  // Additional utility methods for debugging/monitoring

  /// Get cache statistics for debugging
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final hasUser = await hasUserData();
      final hasToken = sharedPreferences.getString(AppConstants.userTokenKey) != null;
      final tokenCachedAt = sharedPreferences.getInt('token_cached_at');
      
      return {
        'hasUserData': hasUser,
        'hasAuthToken': hasToken,
        'tokenCachedAt': tokenCachedAt != null 
            ? DateTime.fromMillisecondsSinceEpoch(tokenCachedAt).toIso8601String()
            : null,
        'cacheSize': _calculateCacheSize(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  int _calculateCacheSize() {
    int totalSize = 0;
    final keys = sharedPreferences.getKeys();
    
    for (String key in keys) {
      if (key.startsWith('cached_') || 
          key == AppConstants.userDataKey || 
          key == AppConstants.userTokenKey) {
        final value = sharedPreferences.get(key);
        if (value is String) {
          totalSize += value.length;
        }
      }
    }
    
    return totalSize;
  }
}