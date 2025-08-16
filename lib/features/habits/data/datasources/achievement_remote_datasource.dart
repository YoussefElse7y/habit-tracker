// File: features/habits/data/datasources/achievement_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/achievement_constants.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/user_stats.dart';
import '../models/achievement_model.dart';
import '../models/user_stats_model.dart';

abstract class AchievementRemoteDataSource {
  Future<List<Achievement>> getAllAchievements();
  Future<List<Achievement>> getUserAchievements(String userId);
  Future<List<Achievement>> checkAndUnlockAchievements(
    String userId,
    Map<String, dynamic> progressData,
  );
  Future<UserStats> getUserStats(String userId);
  Future<UserStats> updateUserStats(
    String userId,
    Map<String, dynamic> updateData,
  );
  Future<Map<String, int>> getAchievementProgress(
    String userId,
    List<Achievement> achievements,
  );
  Future<int> awardPoints(String userId, int points, String reason);
  Future<List<Map<String, dynamic>>> getLeaderboard({
    String? category,
    int limit = 10,
  });
  Future<Map<String, dynamic>> getStreakRecoveryOptions(String userId);
  Future<bool> useStreakRecovery(String userId, String habitId);
  Future<List<Map<String, dynamic>>> getChallenges({
    String? timeFrame,
    String? category,
  });
  Future<Map<String, dynamic>> completeChallenge(
    String userId,
    String challengeId,
  );
}

class AchievementRemoteDataSourceImpl implements AchievementRemoteDataSource {
  final FirebaseFirestore firestore;

  AchievementRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<Achievement>> getAllAchievements() async {
    try {
      // For now, return predefined achievements from constants
      // In a real app, you might store these in Firestore
      return AchievementConstants.allAchievements;
    } catch (e) {
      throw Exception('Failed to load achievements: ${e.toString()}');
    }
  }

  @override
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final userDoc = await firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      if (userDoc.docs.isEmpty) {
        return [];
      }

      return userDoc.docs
          .map((doc) => AchievementModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to load user achievements: ${e.toString()}');
    }
  }

  @override
  Future<List<Achievement>> checkAndUnlockAchievements(
    String userId,
    Map<String, dynamic> progressData,
  ) async {
    try {
      print('🔍 Checking achievements for user: $userId');
      print('📊 Progress data: $progressData');
      
      final allAchievements = AchievementConstants.allAchievements;
      final userAchievements = await getUserAchievements(userId);
      final unlockedAchievementIds = userAchievements.map((a) => a.id).toSet();
      
      print('🎯 Total achievements available: ${allAchievements.length}');
      print('✅ Already unlocked: ${unlockedAchievementIds.length}');
      print('🔒 Locked achievements: ${allAchievements.where((a) => !unlockedAchievementIds.contains(a.id)).length}');
      
      final newAchievements = <Achievement>[];

      for (final achievement in allAchievements) {
        if (unlockedAchievementIds.contains(achievement.id)) {
          print('⏭️ Skipping already unlocked: ${achievement.title}');
          continue;
        }

        final shouldUnlock = _shouldUnlockAchievement(achievement, progressData);
        print('🔍 Checking ${achievement.title} (${achievement.type.name}, requirement: ${achievement.requirement}): $shouldUnlock');
        
        if (shouldUnlock) {
          print('🎉 Unlocking achievement: ${achievement.title}');
          
          // Mark as unlocked
          final unlockedAchievement = achievement.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          );

          // Save to Firestore
          await firestore
              .collection('users')
              .doc(userId)
              .collection('achievements')
              .doc(achievement.id)
              .set(unlockedAchievement.toFirestore());

          newAchievements.add(unlockedAchievement);

          // Award points
          await awardPoints(userId, achievement.points, 'Achievement: ${achievement.title}');
          print('💰 Awarded ${achievement.points} points for: ${achievement.title}');
        }
      }

      print('🎊 Total new achievements unlocked: ${newAchievements.length}');
      return newAchievements;
    } catch (e) {
      print('❌ Error checking achievements: $e');
      throw Exception('Failed to check achievements: ${e.toString()}');
    }
  }

  @override
  Future<UserStats> getUserStats(String userId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        // Create default stats for new user
        final defaultStats = UserStatsModel(
          userId: userId,
          lastActivity: DateTime.now(),
        );
        
        await firestore
            .collection('users')
            .doc(userId)
            .set({'stats': defaultStats.toFirestore()}, SetOptions(merge: true));
        
        return defaultStats;
      }

      final data = userDoc.data();
      final statsData = data?['stats'] as Map<String, dynamic>?;
      
      if (statsData == null) {
        // Create default stats
        final defaultStats = UserStatsModel(
          userId: userId,
          lastActivity: DateTime.now(),
        );
        
        await firestore
            .collection('users')
            .doc(userId)
            .update({'stats': defaultStats.toFirestore()});
        
        return defaultStats;
      }

      return UserStatsModel.fromFirestore(statsData);
    } catch (e) {
      throw Exception('Failed to load user stats: ${e.toString()}');
    }
  }

  @override
  Future<UserStats> updateUserStats(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      print('📊 Updating user stats for user: $userId');
      print('📝 Update data: $updateData');
      
      final currentStats = await getUserStats(userId);
      print('📊 Current stats: totalHabits=${currentStats.totalHabits}, totalPoints=${currentStats.totalPoints}');
      
      final updatedStats = _applyStatsUpdates(currentStats, updateData);
      print('📊 Updated stats: totalHabits=${updatedStats.totalHabits}, totalPoints=${updatedStats.totalPoints}');
      
      // Use set with merge to ensure the document and stats are created if they don't exist
      await firestore
          .collection('users')
          .doc(userId)
          .set({'stats': updatedStats.toFirestore()}, SetOptions(merge: true));
      
      print('✅ User stats updated successfully');
      return updatedStats;
    } catch (e) {
      print('❌ Error updating user stats: $e');
      throw Exception('Failed to update user stats: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, int>> getAchievementProgress(
    String userId,
    List<Achievement> achievements,
  ) async {
    try {
      final userStats = await getUserStats(userId);
      
      return {
        'totalPoints': userStats.totalPoints,
        'currentLevel': userStats.currentLevel,
        'totalHabits': userStats.totalHabits,
        'activeHabits': userStats.activeHabits,
        'totalCompletions': userStats.totalCompletions,
        'currentStreak': userStats.currentStreak,
        'longestStreak': userStats.longestStreak,
        'totalAchievements': userStats.totalAchievements,
        'unlockedAchievements': userStats.unlockedAchievements,
      };
    } catch (e) {
      throw Exception('Failed to get achievement progress: ${e.toString()}');
    }
  }

  @override
  Future<int> awardPoints(String userId, int points, String reason) async {
    try {
      final userRef = firestore.collection('users').doc(userId);
      
      await firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('User not found');
        }
        
        final currentStats = userDoc.data()?['stats'] as Map<String, dynamic>?;
        final currentPoints = currentStats?['totalPoints'] ?? 0;
        final newTotal = currentPoints + points;
        
        transaction.update(userRef, {
          'stats.totalPoints': newTotal,
          'stats.lastActivity': DateTime.now().toIso8601String(),
        });
        
        // Log points transaction
        await firestore
            .collection('users')
            .doc(userId)
            .collection('points_history')
            .add({
          'points': points,
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
          'totalAfter': newTotal,
        });
      });
      
      // Get updated total
      final updatedDoc = await userRef.get();
      final updatedStats = updatedDoc.data()?['stats'] as Map<String, dynamic>?;
      return updatedStats?['totalPoints'] ?? 0;
    } catch (e) {
      throw Exception('Failed to award points: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard({
    String? category,
    int limit = 10,
  }) async {
    try {
      Query query = firestore.collection('users');
      
      if (category != null) {
        query = query.where('stats.categoryStats.$category', isGreaterThan: 0);
      }
      
      final snapshot = await query
          .orderBy('stats.totalPoints', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'userId': doc.id,
          'name': data['name'] ?? 'Anonymous',
          'totalPoints': data['stats']?['totalPoints'] ?? 0,
          'currentLevel': data['stats']?['currentLevel'] ?? 1,
          'totalCompletions': data['stats']?['totalCompletions'] ?? 0,
          'longestStreak': data['stats']?['longestStreak'] ?? 0,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get leaderboard: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getStreakRecoveryOptions(String userId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      
      final recoveryTokens = data?['streakRecoveryTokens'] ?? 0;
      final lastRecoveryUsed = data?['lastStreakRecoveryUsed'];
      
      return {
        'availableTokens': recoveryTokens,
        'lastRecoveryUsed': lastRecoveryUsed,
        'canUseRecovery': recoveryTokens > 0 && 
            (lastRecoveryUsed == null || 
              DateTime.now().difference(DateTime.parse(lastRecoveryUsed)).inDays >= 7),
      };
    } catch (e) {
      throw Exception('Failed to get streak recovery options: ${e.toString()}');
    }
  }

  @override
  Future<bool> useStreakRecovery(String userId, String habitId) async {
    try {
      final options = await getStreakRecoveryOptions(userId);
      
      if (!options['canUseRecovery']) {
        return false;
      }
      
      await firestore.runTransaction((transaction) async {
        final userRef = firestore.collection('users').doc(userId);
        final habitRef = firestore.collection('habits').doc(habitId);
        
        // Update user recovery tokens
        transaction.update(userRef, {
          'streakRecoveryTokens': FieldValue.increment(-1),
          'lastStreakRecoveryUsed': DateTime.now().toIso8601String(),
        });
        
        // Mark habit as recovered (prevent streak break)
        transaction.update(habitRef, {
          'streakRecovered': true,
          'recoveryUsedAt': DateTime.now().toIso8601String(),
        });
      });
      
      return true;
    } catch (e) {
      throw Exception('Failed to use streak recovery: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getChallenges({
    String? timeFrame,
    String? category,
  }) async {
    try {
      // For now, return some predefined challenges
      // In a real app, these would come from Firestore
      return [
        {
          'id': 'daily_master',
          'title': 'Daily Master',
          'description': 'Complete all daily habits for 7 consecutive days',
          'points': 100,
          'timeFrame': 'weekly',
          'category': 'general',
        },
        {
          'id': 'streak_champion',
          'title': 'Streak Champion',
          'description': 'Maintain a 30-day streak on any habit',
          'points': 200,
          'timeFrame': 'monthly',
          'category': 'streak',
        },
        {
          'id': 'category_explorer',
          'title': 'Category Explorer',
          'description': 'Complete habits from 5 different categories',
          'points': 150,
          'timeFrame': 'monthly',
          'category': 'exploration',
        },
      ];
    } catch (e) {
      throw Exception('Failed to get challenges: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> completeChallenge(
    String userId,
    String challengeId,
  ) async {
    try {
      // Mark challenge as completed
      await firestore
          .collection('users')
          .doc(userId)
          .collection('completed_challenges')
          .doc(challengeId)
          .set({
        'completedAt': DateTime.now().toIso8601String(),
        'challengeId': challengeId,
      });
      
      // Award points (challenge points would be defined in the challenge)
      const challengePoints = 100; // This would come from the challenge definition
      await awardPoints(userId, challengePoints, 'Challenge completed');
      
      return {
        'success': true,
        'pointsAwarded': challengePoints,
        'challengeId': challengeId,
      };
    } catch (e) {
      throw Exception('Failed to complete challenge: ${e.toString()}');
    }
  }

  // Helper method to determine if an achievement should be unlocked
  bool _shouldUnlockAchievement(Achievement achievement, Map<String, dynamic> progressData) {
    print('🔍 Checking achievement: ${achievement.title} (${achievement.type.name})');
    print('📊 Progress data for this check: $progressData');
    
    switch (achievement.type) {
      case AchievementType.streak:
        final currentStreak = progressData['currentStreak'] ?? 0;
        final result = currentStreak >= achievement.requirement;
        print('🔥 Streak check: currentStreak=$currentStreak, requirement=${achievement.requirement}, result=$result');
        return result;
        
      case AchievementType.completion:
        final totalCompletions = progressData['totalCompletions'] ?? 0;
        final result = totalCompletions >= achievement.requirement;
        print('✅ Completion check: totalCompletions=$totalCompletions, requirement=${achievement.requirement}, result=$result');
        return result;
        
      case AchievementType.milestone:
        final totalHabits = progressData['totalHabits'] ?? 0;
        final result = totalHabits >= achievement.requirement;
        print('🏆 Milestone check: totalHabits=$totalHabits, requirement=${achievement.requirement}, result=$result');
        return result;
        
      case AchievementType.special:
        // Special achievements have custom logic
        final result = _checkSpecialAchievement(achievement, progressData);
        print('⭐ Special check: result=$result');
        return result;
    }
  }

  // Helper method to check special achievements
  bool _checkSpecialAchievement(Achievement achievement, Map<String, dynamic> progressData) {
    switch (achievement.id) {
      case 'perfect_week':
        final weeklyCompletions = progressData['weeklyCompletions'] ?? 0;
        final weeklyTotal = progressData['weeklyTotal'] ?? 1;
        return weeklyCompletions >= weeklyTotal * 7;
        
      case 'perfect_month':
        final monthlyCompletions = progressData['monthlyCompletions'] ?? 0;
        final monthlyTotal = progressData['monthlyTotal'] ?? 1;
        return monthlyCompletions >= monthlyTotal * 30;
        
      case 'early_bird':
        final completionHour = progressData['completionHour'] ?? 12;
        return completionHour < 6;
        
      case 'night_owl':
        final completionHour = progressData['completionHour'] ?? 12;
        return completionHour > 22;
        
      default:
        return false;
    }
  }

  // Helper method to apply stats updates
  UserStats _applyStatsUpdates(UserStats currentStats, Map<String, dynamic> updates) {
    return currentStats.copyWith(
      totalPoints: updates['totalPoints'] ?? currentStats.totalPoints,
      currentLevel: updates['currentLevel'] ?? currentStats.currentLevel,
      totalHabits: updates['totalHabits'] ?? currentStats.totalHabits,
      activeHabits: updates['activeHabits'] ?? currentStats.activeHabits,
      totalCompletions: updates['totalCompletions'] ?? currentStats.totalCompletions,
      currentStreak: updates['currentStreak'] ?? currentStats.currentStreak,
      longestStreak: updates['longestStreak'] ?? currentStats.longestStreak,
      totalAchievements: updates['totalAchievements'] ?? currentStats.totalAchievements,
      unlockedAchievements: updates['unlockedAchievements'] ?? currentStats.unlockedAchievements,
      lastActivity: updates['lastActivity'] ?? currentStats.lastActivity,
      categoryStats: updates['categoryStats'] ?? currentStats.categoryStats,
      weeklyProgress: updates['weeklyProgress'] ?? currentStats.weeklyProgress,
      monthlyProgress: updates['monthlyProgress'] ?? currentStats.monthlyProgress,
    );
  }
}