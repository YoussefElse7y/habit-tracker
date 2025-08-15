// File: features/habits/data/repositories/achievement_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../datasources/achievement_remote_datasource.dart';
import '../datasources/achievement_local_datasource.dart';

class AchievementRepositoryImpl implements AchievementRepository {
  final AchievementRemoteDataSource remoteDataSource;
  final AchievementLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AchievementRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Achievement>>> getAllAchievements() async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final achievements = await remoteDataSource.getAllAchievements();
          // Cache achievements locally
          await localDataSource.cacheAchievements(achievements);
          return Right(achievements);
        } catch (e) {
          // If remote fails, try local cache
          final cachedAchievements = await localDataSource.getCachedAchievements();
          if (cachedAchievements.isNotEmpty) {
            return Right(cachedAchievements);
          }
          return Left(ServerFailure('Failed to load achievements'));
        }
      } else {
        // Offline: return cached achievements
        final cachedAchievements = await localDataSource.getCachedAchievements();
        if (cachedAchievements.isNotEmpty) {
          return Right(cachedAchievements);
        }
        return const Left(ConnectionFailure('No internet connection and no cached achievements'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Achievement>>> getUserAchievements(String userId) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final achievements = await remoteDataSource.getUserAchievements(userId);
          // Cache user achievements locally
          await localDataSource.cacheUserAchievements(userId, achievements);
          return Right(achievements);
        } catch (e) {
          // If remote fails, try local cache
          final cachedAchievements = await localDataSource.getCachedUserAchievements(userId);
          if (cachedAchievements.isNotEmpty) {
            return Right(cachedAchievements);
          }
          return Left(ServerFailure('Failed to load user achievements'));
        }
      } else {
        // Offline: return cached user achievements
        final cachedAchievements = await localDataSource.getCachedUserAchievements(userId);
        if (cachedAchievements.isNotEmpty) {
          return Right(cachedAchievements);
        }
        return const Left(ConnectionFailure('No internet connection and no cached achievements'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Achievement>>> checkAndUnlockAchievements(
    String userId,
    Map<String, dynamic> progressData,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final newAchievements = await remoteDataSource.checkAndUnlockAchievements(
            userId,
            progressData,
          );
          
          // Update local cache with new achievements
          if (newAchievements.isNotEmpty) {
            final currentAchievements = await localDataSource.getCachedUserAchievements(userId);
            final updatedAchievements = [...currentAchievements, ...newAchievements];
            await localDataSource.cacheUserAchievements(userId, updatedAchievements);
          }
          
          return Right(newAchievements);
        } catch (e) {
          return Left(ServerFailure('Failed to check achievements: ${e.toString()}'));
        }
      } else {
        // Offline: can't check achievements, return empty list
        return const Right([]);
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserStats>> getUserStats(String userId) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final stats = await remoteDataSource.getUserStats(userId);
          // Cache stats locally
          await localDataSource.cacheUserStats(userId, stats);
          return Right(stats);
        } catch (e) {
          // If remote fails, try local cache
          final cachedStats = await localDataSource.getCachedUserStats(userId);
          if (cachedStats != null) {
            return Right(cachedStats);
          }
          return Left(ServerFailure('Failed to load user stats'));
        }
      } else {
        // Offline: return cached stats
        final cachedStats = await localDataSource.getCachedUserStats(userId);
        if (cachedStats != null) {
          return Right(cachedStats);
        }
        return const Left(ConnectionFailure('No internet connection and no cached stats'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserStats>> updateUserStats(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final updatedStats = await remoteDataSource.updateUserStats(userId, updateData);
          // Update local cache
          await localDataSource.cacheUserStats(userId, updatedStats);
          return Right(updatedStats);
        } catch (e) {
          return Left(ServerFailure('Failed to update user stats: ${e.toString()}'));
        }
      } else {
        // Offline: update local cache only
        final currentStats = await localDataSource.getCachedUserStats(userId);
        if (currentStats != null) {
          // Apply updates to cached stats
          final updatedStats = _applyStatsUpdates(currentStats, updateData);
          await localDataSource.cacheUserStats(userId, updatedStats);
          return Right(updatedStats);
        }
        return const Left(ConnectionFailure('No internet connection and no cached stats'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getAchievementProgress(
    String userId,
    List<Achievement> achievements,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          return await remoteDataSource.getAchievementProgress(userId, achievements);
        } catch (e) {
          return Left(ServerFailure('Failed to get achievement progress: ${e.toString()}'));
        }
      } else {
        // Offline: return basic progress from local data
        final userStats = await localDataSource.getCachedUserStats(userId);
        if (userStats != null) {
          return Right({
            'totalPoints': userStats.totalPoints,
            'currentLevel': userStats.currentLevel,
            'totalCompletions': userStats.totalCompletions,
            'currentStreak': userStats.currentStreak,
            'longestStreak': userStats.longestStreak,
          });
        }
        return const Left(ConnectionFailure('No internet connection and no cached stats'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> awardPoints(
    String userId,
    int points,
    String reason,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final newTotal = await remoteDataSource.awardPoints(userId, points, reason);
          
          // Update local cache
          final currentStats = await localDataSource.getCachedUserStats(userId);
          if (currentStats != null) {
            final updatedStats = currentStats.copyWith(totalPoints: newTotal);
            await localDataSource.cacheUserStats(userId, updatedStats);
          }
          
          return Right(newTotal);
        } catch (e) {
          return Left(ServerFailure('Failed to award points: ${e.toString()}'));
        }
      } else {
        // Offline: update local cache only
        final currentStats = await localDataSource.getCachedUserStats(userId);
        if (currentStats != null) {
          final newTotal = currentStats.totalPoints + points;
          final updatedStats = currentStats.copyWith(totalPoints: newTotal);
          await localDataSource.cacheUserStats(userId, updatedStats);
          return Right(newTotal);
        }
        return const Left(ConnectionFailure('No internet connection and no cached stats'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getLeaderboard({
    String? category,
    int limit = 10,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          return await remoteDataSource.getLeaderboard(category: category, limit: limit);
        } catch (e) {
          return Left(ServerFailure('Failed to get leaderboard: ${e.toString()}'));
        }
      } else {
        // Offline: can't get leaderboard
        return const Left(ConnectionFailure('Internet connection required for leaderboard'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getStreakRecoveryOptions(String userId) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          return await remoteDataSource.getStreakRecoveryOptions(userId);
        } catch (e) {
          return Left(ServerFailure('Failed to get streak recovery options: ${e.toString()}'));
        }
      } else {
        // Offline: can't get recovery options
        return const Left(ConnectionFailure('Internet connection required for streak recovery'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> useStreakRecovery(String userId, String habitId) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          return await remoteDataSource.useStreakRecovery(userId, habitId);
        } catch (e) {
          return Left(ServerFailure('Failed to use streak recovery: ${e.toString()}'));
        }
      } else {
        // Offline: can't use recovery
        return const Left(ConnectionFailure('Internet connection required for streak recovery'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getChallenges({
    String? timeFrame,
    String? category,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          return await remoteDataSource.getChallenges(timeFrame: timeFrame, category: category);
        } catch (e) {
          return Left(ServerFailure('Failed to get challenges: ${e.toString()}'));
        }
      } else {
        // Offline: can't get challenges
        return const Left(ConnectionFailure('Internet connection required for challenges'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> completeChallenge(
    String userId,
    String challengeId,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          return await remoteDataSource.completeChallenge(userId, challengeId);
        } catch (e) {
          return Left(ServerFailure('Failed to complete challenge: ${e.toString()}'));
        }
      } else {
        // Offline: can't complete challenges
        return const Left(ConnectionFailure('Internet connection required for challenges'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  // Helper method to apply stats updates locally
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