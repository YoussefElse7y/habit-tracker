// File: features/habits/data/datasources/achievement_local_datasource.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/user_stats.dart';
import '../models/achievement_model.dart';
import '../models/user_stats_model.dart';

abstract class AchievementLocalDataSource {
  Future<void> cacheAchievements(List<Achievement> achievements);
  Future<List<Achievement>> getCachedAchievements();
  Future<void> cacheUserAchievements(String userId, List<Achievement> achievements);
  Future<List<Achievement>> getCachedUserAchievements(String userId);
  Future<void> cacheUserStats(String userId, UserStats stats);
  Future<UserStats?> getCachedUserStats(String userId);
  Future<void> clearAllCachedData();
  Future<void> clearUserData(String userId);
}

class AchievementLocalDataSourceImpl implements AchievementLocalDataSource {
  final SharedPreferences sharedPreferences;

  AchievementLocalDataSourceImpl({required this.sharedPreferences});

  static const String _achievementsKey = 'cached_achievements';
  static const String _userAchievementsPrefix = 'user_achievements_';
  static const String _userStatsPrefix = 'user_stats_';

  @override
  Future<void> cacheAchievements(List<Achievement> achievements) async {
    try {
      final achievementsJson =
          achievements.map((achievement) => achievement.toJson()).toList();
      await sharedPreferences.setString(
        _achievementsKey,
        jsonEncode(achievementsJson),
      );
    } catch (e) {
      throw Exception('Failed to cache achievements: ${e.toString()}');
    }
  }

  @override
  Future<List<Achievement>> getCachedAchievements() async {
    try {
      final achievementsString = sharedPreferences.getString(_achievementsKey);
      if (achievementsString == null) return [];
      final achievementsJson = jsonDecode(achievementsString) as List;
      return achievementsJson
          .map((json) => AchievementModel.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheUserAchievements(
      String userId, List<Achievement> achievements) async {
    try {
      final key = '$_userAchievementsPrefix$userId';
      final achievementsJson =
          achievements.map((achievement) => achievement.toJson()).toList();
      await sharedPreferences.setString(
        key,
        jsonEncode(achievementsJson),
      );
    } catch (e) {
      throw Exception('Failed to cache user achievements: ${e.toString()}');
    }
  }

  @override
  Future<List<Achievement>> getCachedUserAchievements(String userId) async {
    try {
      final key = '$_userAchievementsPrefix$userId';
      final achievementsString = sharedPreferences.getString(key);
      if (achievementsString == null) return [];
      final achievementsJson = jsonDecode(achievementsString) as List;
      return achievementsJson
          .map((json) => AchievementModel.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheUserStats(String userId, UserStats stats) async {
    try {
      final key = '$_userStatsPrefix$userId';
      final statsJson = stats.toJson();
      await sharedPreferences.setString(
        key,
        jsonEncode(statsJson),
      );
    } catch (e) {
      throw Exception('Failed to cache user stats: ${e.toString()}');
    }
  }

  @override
  Future<UserStats?> getCachedUserStats(String userId) async {
    try {
      final key = '$_userStatsPrefix$userId';
      final statsString = sharedPreferences.getString(key);
      if (statsString == null) return null;
      final statsJson = jsonDecode(statsString) as Map<String, dynamic>;
      return UserStatsModel.fromJson(statsJson);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearAllCachedData() async {
    try {
      final keys = sharedPreferences.getKeys();
      final keysToRemove = keys.where((key) =>
          key == _achievementsKey ||
          key.startsWith(_userAchievementsPrefix) ||
          key.startsWith(_userStatsPrefix));
      for (final key in keysToRemove) {
        await sharedPreferences.remove(key);
      }
    } catch (e) {
      throw Exception('Failed to clear cached data: ${e.toString()}');
    }
  }

  @override
  Future<void> clearUserData(String userId) async {
    try {
      await sharedPreferences
          .remove('$_userAchievementsPrefix$userId');
      await sharedPreferences.remove('$_userStatsPrefix$userId');
    } catch (e) {
      throw Exception('Failed to clear user data: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final keys = sharedPreferences.getKeys();
      int achievementsCount = 0;
      int userAchievementsCount = 0;
      int userStatsCount = 0;

      for (final key in keys) {
        if (key == _achievementsKey) {
          achievementsCount = (await getCachedAchievements()).length;
        } else if (key.startsWith(_userAchievementsPrefix)) {
          final userId = key.substring(_userAchievementsPrefix.length);
          userAchievementsCount +=
              (await getCachedUserAchievements(userId)).length;
        } else if (key.startsWith(_userStatsPrefix)) {
          userStatsCount++;
        }
      }

      return {
        'totalCachedAchievements': achievementsCount,
        'totalCachedUserAchievements': userAchievementsCount,
        'totalCachedUserStats': userStatsCount,
        'totalCacheKeys': keys.length,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  bool _isCacheValid(String key,
      {Duration maxAge = const Duration(hours: 24)}) {
    try {
      final lastUpdatedKey = '${key}_last_updated';
      final lastUpdatedString = sharedPreferences.getString(lastUpdatedKey);
      if (lastUpdatedString == null) return false;
      final lastUpdated = DateTime.parse(lastUpdatedString);
      return DateTime.now().difference(lastUpdated) < maxAge;
    } catch (_) {
      return false;
    }
  }

  Future<void> _updateCacheTimestamp(String key) async {
    try {
      await sharedPreferences.setString(
        '${key}_last_updated',
        DateTime.now().toIso8601String(),
      );
    } catch (_) {}
  }

  Future<void> cacheAchievementsWithTimestamp(
      List<Achievement> achievements) async {
    await cacheAchievements(achievements);
    await _updateCacheTimestamp(_achievementsKey);
  }

  Future<void> cacheUserAchievementsWithTimestamp(
      String userId, List<Achievement> achievements) async {
    await cacheUserAchievements(userId, achievements);
    await _updateCacheTimestamp('$_userAchievementsPrefix$userId');
  }

  Future<void> cacheUserStatsWithTimestamp(
      String userId, UserStats stats) async {
    await cacheUserStats(userId, stats);
    await _updateCacheTimestamp('$_userStatsPrefix$userId');
  }

  Future<List<Achievement>> getValidCachedAchievements() async {
    if (!_isCacheValid(_achievementsKey)) return [];
    return getCachedAchievements();
  }

  Future<List<Achievement>> getValidCachedUserAchievements(
      String userId) async {
    final key = '$_userAchievementsPrefix$userId';
    if (!_isCacheValid(key)) return [];
    return getCachedUserAchievements(userId);
  }

  Future<UserStats?> getValidCachedUserStats(String userId) async {
    final key = '$_userStatsPrefix$userId';
    if (!_isCacheValid(key)) return null;
    return getCachedUserStats(userId);
  }
}
