// File: features/habits/domain/repositories/achievement_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/achievement.dart';
import '../entities/user_stats.dart';

abstract class AchievementRepository {
  /// Get all available achievements
  Future<Either<Failure, List<Achievement>>> getAllAchievements();
  
  /// Get user's unlocked achievements
  Future<Either<Failure, List<Achievement>>> getUserAchievements(String userId);
  
  /// Check and unlock new achievements based on user progress
  Future<Either<Failure, List<Achievement>>> checkAndUnlockAchievements(
    String userId,
    Map<String, dynamic> progressData,
  );
  
  /// Get user statistics and progress
  Future<Either<Failure, UserStats>> getUserStats(String userId);
  
  /// Update user stats after habit completion
  Future<Either<Failure, UserStats>> updateUserStats(
    String userId,
    Map<String, dynamic> updateData,
  );
  
  /// Get achievement progress for a specific user
  Future<Either<Failure, Map<String, int>>> getAchievementProgress(
    String userId,
    List<Achievement> achievements,
  );
  
  /// Award points to user
  Future<Either<Failure, int>> awardPoints(
    String userId,
    int points,
    String reason,
  );
  
  /// Get leaderboard data (top users by points/streaks)
  Future<Either<Failure, List<Map<String, dynamic>>>> getLeaderboard({
    String? category,
    int limit = 10,
  });
  
  /// Get streak recovery options
  Future<Either<Failure, Map<String, dynamic>>> getStreakRecoveryOptions(String userId);
  
  /// Use streak recovery (allow user to save a broken streak)
  Future<Either<Failure, bool>> useStreakRecovery(String userId, String habitId);
  
  /// Get daily/weekly/monthly challenges
  Future<Either<Failure, List<Map<String, dynamic>>>> getChallenges({
    String? timeFrame,
    String? category,
  });
  
  /// Complete a challenge
  Future<Either<Failure, Map<String, dynamic>>> completeChallenge(
    String userId,
    String challengeId,
  );
}
