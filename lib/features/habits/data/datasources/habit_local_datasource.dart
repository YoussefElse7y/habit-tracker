// File: features/habits/data/datasources/habit_local_datasource.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/habit_model.dart';


abstract class HabitLocalDataSource {
  /// Cache a single habit locally
  Future<void> cacheHabit(HabitModel habit);
  
  /// Cache multiple habits locally
  Future<void> cacheHabits(List<HabitModel> habits);
  
  /// Get all cached habits for a user
  Future<List<HabitModel>> getCachedHabits(String userId);
  
  /// Get a specific habit from cache
  Future<HabitModel?> getCachedHabitById(String habitId);
  
  /// Update a cached habit
  Future<void> updateCachedHabit(HabitModel habit);
  
  /// Remove a habit from cache
  Future<void> removeCachedHabit(String habitId);
  
  /// Clear all cached habits for a user
  Future<void> clearCachedHabits(String userId);
  
  /// Clear all cache data
  Future<void> clearAllCacheData();
  
  /// Check if habits are cached for user
  Future<bool> hasHabitsCache(String userId);
  
  /// Get last cache update time
  Future<DateTime?> getLastCacheUpdate(String userId);
  
  /// Set last cache update time
  Future<void> setLastCacheUpdate(String userId);
}

class HabitLocalDataSourceImpl implements HabitLocalDataSource {
  final SharedPreferences sharedPreferences;

  HabitLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheHabit(HabitModel habit) async {
    try {
      // Get existing cached habits
      final cachedHabits = await getCachedHabits(habit.userId);
      
      // Find if habit already exists and update it, or add new one
      final existingIndex = cachedHabits.indexWhere((h) => h.id == habit.id);
      
      if (existingIndex != -1) {
        // Update existing habit
        cachedHabits[existingIndex] = habit;
      } else {
        // Add new habit
        cachedHabits.add(habit);
      }
      
      // Save updated list
      await cacheHabits(cachedHabits);
    } catch (e) {
      throw CacheException('Failed to cache habit: ${e.toString()}');
    }
  }

  @override
  Future<void> cacheHabits(List<HabitModel> habits) async {
    try {
      if (habits.isEmpty) return;
      
      // Group habits by userId since we store them separately for each user
      final habitsByUser = <String, List<HabitModel>>{};
      
      for (var habit in habits) {
        if (!habitsByUser.containsKey(habit.userId)) {
          habitsByUser[habit.userId] = [];
        }
        habitsByUser[habit.userId]!.add(habit);
      }
      
      // Cache habits for each user
      for (var entry in habitsByUser.entries) {
        final userId = entry.key;
        final userHabits = entry.value;
        
        final key = _getHabitsKey(userId);
        final jsonList = userHabits.map((habit) => habit.toJson()).toList();
        final jsonString = jsonEncode(jsonList);
        
        await sharedPreferences.setString(key, jsonString);
        await setLastCacheUpdate(userId);
      }
    } catch (e) {
      throw CacheException('Failed to cache habits: ${e.toString()}');
    }
  }

  @override
  Future<List<HabitModel>> getCachedHabits(String userId) async {
    try {
      final key = _getHabitsKey(userId);
      final jsonString = sharedPreferences.getString(key);
      
      if (jsonString == null) {
        return []; // No cached habits for this user
      }
      
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      
      return jsonList
          .map((json) => HabitModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CacheException('Failed to get cached habits: ${e.toString()}');
    }
  }

  @override
  Future<HabitModel?> getCachedHabitById(String habitId) async {
    try {
      // We need to search through all users' cached habits
      // In a real app, you might want to optimize this by storing userId separately
      final allKeys = sharedPreferences.getKeys()
          .where((key) => key.startsWith('${AppConstants.habitsKey}_'))
          .toList();
      
      for (var key in allKeys) {
        final jsonString = sharedPreferences.getString(key);
        if (jsonString != null) {
          final jsonList = jsonDecode(jsonString) as List<dynamic>;
          
          for (var json in jsonList) {
            final habit = HabitModel.fromJson(json as Map<String, dynamic>);
            if (habit.id == habitId) {
              return habit;
            }
          }
        }
      }
      
      return null; // Habit not found in cache
    } catch (e) {
      throw CacheException('Failed to get cached habit by ID: ${e.toString()}');
    }
  }

  @override
  Future<void> updateCachedHabit(HabitModel habit) async {
    try {
      // This is the same as cacheHabit - it will update if exists or add if not
      await cacheHabit(habit);
    } catch (e) {
      throw CacheException('Failed to update cached habit: ${e.toString()}');
    }
  }

  @override
  Future<void> removeCachedHabit(String habitId) async {
    try {
      // First find which user this habit belongs to
      final habitToRemove = await getCachedHabitById(habitId);
      if (habitToRemove == null) return; // Habit not in cache
      
      // Get all habits for this user
      final userHabits = await getCachedHabits(habitToRemove.userId);
      
      // Remove the specific habit
      final updatedHabits = userHabits.where((habit) => habit.id != habitId).toList();
      
      // Save updated list
      if (updatedHabits.isNotEmpty) {
        await cacheHabits(updatedHabits);
      } else {
        // No habits left for this user, clear their cache
        await clearCachedHabits(habitToRemove.userId);
      }
    } catch (e) {
      throw CacheException('Failed to remove cached habit: ${e.toString()}');
    }
  }

  @override
  Future<void> clearCachedHabits(String userId) async {
    try {
      final key = _getHabitsKey(userId);
      await sharedPreferences.remove(key);
      
      // Also remove last cache update time
      final cacheTimeKey = _getCacheTimeKey(userId);
      await sharedPreferences.remove(cacheTimeKey);
    } catch (e) {
      throw CacheException('Failed to clear cached habits: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAllCacheData() async {
    try {
      // Get all habit-related keys
      final keysToRemove = sharedPreferences.getKeys()
          .where((key) => 
              key.startsWith('${AppConstants.habitsKey}_') || 
              key.startsWith('cache_time_habits_'))
          .toList();
      
      // Remove all habit cache keys
      for (var key in keysToRemove) {
        await sharedPreferences.remove(key);
      }
    } catch (e) {
      throw CacheException('Failed to clear all cache data: ${e.toString()}');
    }
  }

  @override
  Future<bool> hasHabitsCache(String userId) async {
    try {
      final key = _getHabitsKey(userId);
      return sharedPreferences.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<DateTime?> getLastCacheUpdate(String userId) async {
    try {
      final key = _getCacheTimeKey(userId);
      final timeString = sharedPreferences.getString(key);
      
      if (timeString == null) return null;
      
      return DateTime.parse(timeString);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> setLastCacheUpdate(String userId) async {
    try {
      final key = _getCacheTimeKey(userId);
      final currentTime = DateTime.now().toIso8601String();
      
      await sharedPreferences.setString(key, currentTime);
    } catch (e) {
      throw CacheException('Failed to set cache update time: ${e.toString()}');
    }
  }

  // Helper methods for generating cache keys
  
  String _getHabitsKey(String userId) {
    return '${AppConstants.habitsKey}_$userId';
  }
  
  String _getCacheTimeKey(String userId) {
    return 'cache_time_habits_$userId';
  }
}