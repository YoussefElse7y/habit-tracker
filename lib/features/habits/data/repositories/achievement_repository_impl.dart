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
          await localDataSource.cacheAchievements(achievements);
          return Right(achievements);
        } catch (e) {
          final cached = await localDataSource.getCachedAchievements();
          if (cached.isNotEmpty) return Right(cached);
          return Left(ServerFailure('Failed to load achievements'));
        }
      } else {
        final cached = await localDataSource.getCachedAchievements();
        if (cached.isNotEmpty) return Right(cached);
        return const Left(ConnectionFailure(
            'No internet connection and no cached achievements'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Achievement>>> getUserAchievements(
      String userId) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final achievements =
              await remoteDataSource.getUserAchievements(userId);
          await localDataSource.cacheUserAchievements(userId, achievements);
          return Right(achievements);
        } catch (e) {
          final cached = await localDataSource.getCachedUserAchievements(userId);
          if (cached.isNotEmpty) return Right(cached);
          return Left(ServerFailure('Failed to load user achievements'));
        }
      } else {
        final cached = await localDataSource.getCachedUserAchievements(userId);
        if (cached.isNotEmpty) return Right(cached);
        return const Left(ConnectionFailure(
            'No internet connection and no cached achievements'));
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
              userId, progressData);

          if (newAchievements.isNotEmpty) {
            final current = await localDataSource.getCachedUserAchievements(userId);
            final updated = [...current, ...newAchievements];
            await localDataSource.cacheUserAchievements(userId, updated);
          }

          return Right(newAchievements);
        } catch (e) {
          return Left(ServerFailure('Failed to check achievements: ${e.toString()}'));
        }
      } else {
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
          await localDataSource.cacheUserStats(userId, stats);
          return Right(stats);
        } catch (e) {
          final cached = await localDataSource.getCachedUserStats(userId);
          if (cached != null) return Right(cached);
          return Left(ServerFailure('Failed to load user stats'));
        }
      } else {
        final cached = await localDataSource.getCachedUserStats(userId);
        if (cached != null) return Right(cached);
        return const Left(ConnectionFailure(
            'No internet connection and no cached stats'));
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
          final updated = await remoteDataSource.updateUserStats(userId, updateData);
          await localDataSource.cacheUserStats(userId, updated);
          return Right(updated);
        } catch (e) {
          return Left(ServerFailure('Failed to update user stats: ${e.toString()}'));
        }
      } else {
        final current = await localDataSource.getCachedUserStats(userId);
        if (current != null) {
          final updated = _applyStatsUpdates(current, updateData);
          await localDataSource.cacheUserStats(userId, updated);
          return Right(updated);
        }
        return const Left(ConnectionFailure(
            'No internet connection and no cached stats'));
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
          final progress =
              await remoteDataSource.getAchievementProgress(userId, achievements);
          return Right(progress);
        } catch (e) {
          return Left(ServerFailure(
              'Failed to get achievement progress: ${e.toString()}'));
        }
      } else {
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
        return const Left(ConnectionFailure(
            'No internet connection and no cached stats'));
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
          final currentStats = await localDataSource.getCachedUserStats(userId);
          if (currentStats != null) {
            final updated = currentStats.copyWith(totalPoints: newTotal);
            await localDataSource.cacheUserStats(userId, updated);
          }
          return Right(newTotal);
        } catch (e) {
          return Left(ServerFailure('Failed to award points: ${e.toString()}'));
        }
      } else {
        final currentStats = await localDataSource.getCachedUserStats(userId);
        if (currentStats != null) {
          final newTotal = currentStats.totalPoints + points;
          final updated = currentStats.copyWith(totalPoints: newTotal);
          await localDataSource.cacheUserStats(userId, updated);
          return Right(newTotal);
        }
        return const Left(ConnectionFailure(
            'No internet connection and no cached stats'));
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
          final leaderboard =
              await remoteDataSource.getLeaderboard(category: category, limit: limit);
          return Right(leaderboard);
        } catch (e) {
          return Left(ServerFailure('Failed to get leaderboard: ${e.toString()}'));
        }
      } else {
        return const Left(ConnectionFailure(
            'Internet connection required for leaderboard'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getStreakRecoveryOptions(
      String userId) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final options = await remoteDataSource.getStreakRecoveryOptions(userId);
          return Right(options);
        } catch (e) {
          return Left(ServerFailure(
              'Failed to get streak recovery options: ${e.toString()}'));
        }
      } else {
        return const Left(ConnectionFailure(
            'Internet connection required for streak recovery'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> useStreakRecovery(
      String userId, String habitId) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final result = await remoteDataSource.useStreakRecovery(userId, habitId);
          return Right(result);
        } catch (e) {
          return Left(ServerFailure('Failed to use streak recovery: ${e.toString()}'));
        }
      } else {
        return const Left(ConnectionFailure(
            'Internet connection required for streak recovery'));
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
          final challenges =
              await remoteDataSource.getChallenges(timeFrame: timeFrame, category: category);
          return Right(challenges);
        } catch (e) {
          return Left(ServerFailure('Failed to get challenges: ${e.toString()}'));
        }
      } else {
        return const Left(ConnectionFailure(
            'Internet connection required for challenges'));
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
          final result =
              await remoteDataSource.completeChallenge(userId, challengeId);
          return Right(result);
        } catch (e) {
          return Left(ServerFailure('Failed to complete challenge: ${e.toString()}'));
        }
      } else {
        return const Left(ConnectionFailure(
            'Internet connection required for challenges'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  UserStats _applyStatsUpdates(
      UserStats currentStats, Map<String, dynamic> updates) {
    return currentStats.copyWith(
      totalPoints: updates['totalPoints'] ?? currentStats.totalPoints,
      currentLevel: updates['currentLevel'] ?? currentStats.currentLevel,
      totalHabits: updates['totalHabits'] ?? currentStats.totalHabits,
      activeHabits: updates['activeHabits'] ?? currentStats.activeHabits,
      totalCompletions:
          updates['totalCompletions'] ?? currentStats.totalCompletions,
      currentStreak: updates['currentStreak'] ?? currentStats.currentStreak,
      longestStreak: updates['longestStreak'] ?? currentStats.longestStreak,
      totalAchievements:
          updates['totalAchievements'] ?? currentStats.totalAchievements,
      unlockedAchievements:
          updates['unlockedAchievements'] ?? currentStats.unlockedAchievements,
      lastActivity: updates['lastActivity'] ?? currentStats.lastActivity,
      categoryStats: updates['categoryStats'] ?? currentStats.categoryStats,
      weeklyProgress: updates['weeklyProgress'] ?? currentStats.weeklyProgress,
      monthlyProgress:
          updates['monthlyProgress'] ?? currentStats.monthlyProgress,
    );
  }
}
