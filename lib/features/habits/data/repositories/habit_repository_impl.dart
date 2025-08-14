// File: features/habits/data/repositories/habit_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../datasources/habit_remote_datasource.dart';
import '../datasources/habit_local_datasource.dart';
import '../models/habit_model.dart';

class HabitRepositoryImpl implements HabitRepository {
  final HabitRemoteDataSource remoteDataSource;
  final HabitLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  HabitRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Habit>> createHabit(Habit habit) async {
    try {
      // Convert domain entity to data model
      final habitModel = HabitModel(
        id: habit.id,
        userId: habit.userId,
        title: habit.title,
        description: habit.description,
        category: habit.category,
        frequency: habit.frequency,
        createdAt: habit.createdAt,
        updatedAt: habit.updatedAt,
        isActive: habit.isActive,
        currentStreak: habit.currentStreak,
        longestStreak: habit.longestStreak,
        totalCompletions: habit.totalCompletions,
        lastCompletedAt: habit.lastCompletedAt,
        customDays: habit.customDays,
        targetCount: habit.targetCount,
      );

      if (await networkInfo.isConnected) {
        // Online: Create in remote first, then cache locally
        final createdHabit = await remoteDataSource.createHabit(habitModel);
        
        // Cache the created habit locally
        await localDataSource.cacheHabit(createdHabit);
        
        return Right(createdHabit);
      } else {
        // Offline: Cache locally only (will sync later)
        await localDataSource.cacheHabit(habitModel);
        
        // Return the habit (will be synced when online)
        return Right(habitModel);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error creating habit: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Habit>>> getAllHabits() async {
    try {
      // Get current user ID (you'll need to inject this or get it from auth)
      // For now, we'll assume you have a way to get the current user ID
      const String currentUserId = 'current_user_id'; // TODO: Get from auth service

      if (await networkInfo.isConnected) {
        try {
          // Online: Get from remote and update cache
          final remoteHabits = await remoteDataSource.getAllHabits(currentUserId);
          
          // Update local cache with fresh data
          await localDataSource.cacheHabits(remoteHabits);
          
          return Right(remoteHabits.cast<Habit>());
        } on ServerException catch (e) {
          // If remote fails, fall back to cache
          return await _getFallbackHabits(currentUserId, e.message);
        }
      } else {
        // Offline: Get from cache
        final cachedHabits = await localDataSource.getCachedHabits(currentUserId);
        return Right(cachedHabits.cast<Habit>());
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error getting habits: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Habit>>> getActiveHabits() async {
    try {
      const String currentUserId = 'current_user_id'; // TODO: Get from auth service

      if (await networkInfo.isConnected) {
        try {
          final remoteHabits = await remoteDataSource.getActiveHabits(currentUserId);
          
          // Update cache with active habits
          for (var habit in remoteHabits) {
            await localDataSource.cacheHabit(habit);
          }
          
          return Right(remoteHabits.cast<Habit>());
        } on ServerException catch (e) {
          return await _getFallbackActiveHabits(currentUserId, e.message);
        }
      } else {
        // Offline: Filter cached habits for active ones
        final cachedHabits = await localDataSource.getCachedHabits(currentUserId);
        final activeHabits = cachedHabits.where((habit) => habit.isActive).toList();
        return Right(activeHabits.cast<Habit>());
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error getting active habits: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Habit>>> getHabitsByCategory(HabitCategory category) async {
    try {
      const String currentUserId = 'current_user_id'; // TODO: Get from auth service

      if (await networkInfo.isConnected) {
        try {
          final remoteHabits = await remoteDataSource.getHabitsByCategory(currentUserId, category);
          
          // Update cache
          for (var habit in remoteHabits) {
            await localDataSource.cacheHabit(habit);
          }
          
          return Right(remoteHabits.cast<Habit>());
        } on ServerException catch (e) {
          return await _getFallbackHabitsByCategory(currentUserId, category, e.message);
        }
      } else {
        // Offline: Filter cached habits by category
        final cachedHabits = await localDataSource.getCachedHabits(currentUserId);
        final categoryHabits = cachedHabits
            .where((habit) => habit.category == category && habit.isActive)
            .toList();
        return Right(categoryHabits.cast<Habit>());
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error getting habits by category: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Habit>> getHabitById(String habitId) async {
    try {
      // Try cache first for better performance
      final cachedHabit = await localDataSource.getCachedHabitById(habitId);
      
      if (await networkInfo.isConnected) {
        try {
          // Get latest version from remote
          final remoteHabit = await remoteDataSource.getHabitById(habitId);
          
          // Update cache with latest version
          await localDataSource.cacheHabit(remoteHabit);
          
          return Right(remoteHabit);
        } on ServerException catch (e) {
          // If remote fails but we have cache, return cached version
          if (cachedHabit != null) {
            return Right(cachedHabit);
          }
          return Left(ServerFailure(e.message));
        }
      } else {
        // Offline: Return cached version or error
        if (cachedHabit != null) {
          return Right(cachedHabit);
        }
        return const Left(ConnectionFailure('No internet connection and habit not found in cache'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error getting habit: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Habit>> updateHabit(Habit habit) async {
    try {
      // Convert domain entity to data model
      final habitModel = HabitModel(
        id: habit.id,
        userId: habit.userId,
        title: habit.title,
        description: habit.description,
        category: habit.category,
        frequency: habit.frequency,
        createdAt: habit.createdAt,
        updatedAt: DateTime.now(), // Set current time for update
        isActive: habit.isActive,
        currentStreak: habit.currentStreak,
        longestStreak: habit.longestStreak,
        totalCompletions: habit.totalCompletions,
        lastCompletedAt: habit.lastCompletedAt,
        customDays: habit.customDays,
        targetCount: habit.targetCount,
      );

      if (await networkInfo.isConnected) {
        try {
          // Update in remote first
          final updatedHabit = await remoteDataSource.updateHabit(habitModel);
          
          // Update local cache
          await localDataSource.updateCachedHabit(updatedHabit);
          
          return Right(updatedHabit);
        } on ServerException catch (e) {
          // If remote update fails, still update cache for offline sync later
          await localDataSource.updateCachedHabit(habitModel);
          return Left(ServerFailure('Remote update failed: ${e.message}'));
        }
      } else {
        // Offline: Update cache only (will sync when online)
        await localDataSource.updateCachedHabit(habitModel);
        return Right(habitModel);
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error updating habit: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHabit(String habitId) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          // Delete from remote first
          await remoteDataSource.deleteHabit(habitId);
          
          // Remove from local cache
          await localDataSource.removeCachedHabit(habitId);
          
          return const Right(null);
        } on ServerException catch (e) {
          return Left(ServerFailure(e.message));
        }
      } else {
        // Offline: Mark for deletion in cache (you might want to implement a "deleted" flag)
        await localDataSource.removeCachedHabit(habitId);
        return const Right(null);
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error deleting habit: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Habit>> completeHabit(String habitId) async {
    try {
      // Get current habit
      final habitResult = await getHabitById(habitId);
      
      return await habitResult.fold(
        (failure) async => Left(failure),
        (habit) async {
          // Create updated habit with completion
          final updatedHabit = _markHabitAsCompleted(habit);
          
          // Update the habit
          return await updateHabit(updatedHabit);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Unexpected error completing habit: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Habit>> uncompleteHabit(String habitId) async {
    try {
      // Get current habit
      final habitResult = await getHabitById(habitId);
      
      return await habitResult.fold(
        (failure) async => Left(failure),
        (habit) async {
          // Create updated habit with completion removed
          final updatedHabit = _markHabitAsUncompleted(habit);
          
          // Update the habit
          return await updateHabit(updatedHabit);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Unexpected error uncompleting habit: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<DateTime, bool>>> getHabitHistory({
    required String habitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final history = await remoteDataSource.getHabitHistory(habitId, startDate, endDate);
        return Right(history);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(ConnectionFailure('Internet connection required for habit history'));
    }
  }

  @override
  Future<Either<Failure, List<Habit>>> getTodaysHabits() async {
    try {
      const String currentUserId = 'current_user_id'; // TODO: Get from auth service

      if (await networkInfo.isConnected) {
        try {
          final remoteHabits = await remoteDataSource.getTodaysHabits(currentUserId);
          
          // Update cache
          for (var habit in remoteHabits) {
            await localDataSource.cacheHabit(habit);
          }
          
          return Right(remoteHabits.cast<Habit>());
        } on ServerException catch (e) {
          return await _getFallbackTodaysHabits(currentUserId, e.message);
        }
      } else {
        // Offline: Get today's habits from cache
        final cachedHabits = await localDataSource.getCachedHabits(currentUserId);
        final todaysHabits = cachedHabits.where((habit) => habit.shouldShowToday()).toList();
        return Right(todaysHabits.cast<Habit>());
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error getting today\'s habits: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, HabitStats>> getHabitStats() async {
    try {
      const String currentUserId = 'current_user_id'; // TODO: Get from auth service

      if (await networkInfo.isConnected) {
        try {
          final stats = await remoteDataSource.getHabitStats(currentUserId);
          return Right(stats);
        } on ServerException catch (e) {
          return Left(ServerFailure(e.message));
        }
      } else {
        return const Left(ConnectionFailure('Internet connection required for habit statistics'));
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error getting habit stats: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Habit>> toggleHabitActive(String habitId) async {
    try {
      final habitResult = await getHabitById(habitId);
      
      return await habitResult.fold(
        (failure) async => Left(failure),
        (habit) async {
          // Toggle the isActive status
          final updatedHabit = Habit(
            id: habit.id,
            userId: habit.userId,
            title: habit.title,
            description: habit.description,
            category: habit.category,
            frequency: habit.frequency,
            createdAt: habit.createdAt,
            updatedAt: DateTime.now(),
            isActive: !habit.isActive, // Toggle active status
            currentStreak: habit.currentStreak,
            longestStreak: habit.longestStreak,
            totalCompletions: habit.totalCompletions,
            lastCompletedAt: habit.lastCompletedAt,
            customDays: habit.customDays,
            targetCount: habit.targetCount,
          );
          
          return await updateHabit(updatedHabit);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Unexpected error toggling habit: ${e.toString()}'));
    }
  }

 @override
Stream<Either<Failure, List<Habit>>> watchAllHabits() {
  const String currentUserId = 'current_user_id'; 

  return remoteDataSource.watchAllHabits(currentUserId).map<Either<Failure, List<Habit>>>(
    (habits) => Right<Failure, List<Habit>>(habits.cast<Habit>()),
  ).handleError((error, stackTrace) {
    // handleError cannot change the stream type, so we must use `onErrorReturn`
    // If your Stream library doesn't have that, use `transform` instead
  });
}

@override
Stream<Either<Failure, List<Habit>>> watchTodaysHabits() {
  const String currentUserId = 'current_user_id'; // TODO: Get from auth service

  return remoteDataSource.watchTodaysHabits(currentUserId).map<Either<Failure, List<Habit>>>(
    (habits) => Right<Failure, List<Habit>>(habits.cast<Habit>()),
  ).handleError((error, stackTrace) {
    // Same note as above
  });
}


  // Helper methods for fallback scenarios

  Future<Either<Failure, List<Habit>>> _getFallbackHabits(String userId, String originalError) async {
    try {
      final cachedHabits = await localDataSource.getCachedHabits(userId);
      if (cachedHabits.isNotEmpty) {
        return Right(cachedHabits.cast<Habit>());
      }
      return Left(ServerFailure(originalError));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  Future<Either<Failure, List<Habit>>> _getFallbackActiveHabits(String userId, String originalError) async {
    try {
      final cachedHabits = await localDataSource.getCachedHabits(userId);
      final activeHabits = cachedHabits.where((habit) => habit.isActive).toList();
      if (activeHabits.isNotEmpty) {
        return Right(activeHabits.cast<Habit>());
      }
      return Left(ServerFailure(originalError));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  Future<Either<Failure, List<Habit>>> _getFallbackHabitsByCategory(String userId, HabitCategory category, String originalError) async {
    try {
      final cachedHabits = await localDataSource.getCachedHabits(userId);
      final categoryHabits = cachedHabits
          .where((habit) => habit.category == category && habit.isActive)
          .toList();
      if (categoryHabits.isNotEmpty) {
        return Right(categoryHabits.cast<Habit>());
      }
      return Left(ServerFailure(originalError));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  Future<Either<Failure, List<Habit>>> _getFallbackTodaysHabits(String userId, String originalError) async {
    try {
      final cachedHabits = await localDataSource.getCachedHabits(userId);
      final todaysHabits = cachedHabits.where((habit) => habit.shouldShowToday()).toList();
      if (todaysHabits.isNotEmpty) {
        return Right(todaysHabits.cast<Habit>());
      }
      return Left(ServerFailure(originalError));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  Habit _markHabitAsCompleted(Habit habit) {
    final now = DateTime.now();
    
    // Calculate new streak (simplified - you might want to use the logic from CompleteHabit use case)
    final newStreak = habit.lastCompletedAt != null && 
                     _isSameDay(habit.lastCompletedAt!, now.subtract(const Duration(days: 1)))
        ? habit.currentStreak + 1
        : 1;
    
    return Habit(
      id: habit.id,
      userId: habit.userId,
      title: habit.title,
      description: habit.description,
      category: habit.category,
      frequency: habit.frequency,
      createdAt: habit.createdAt,
      updatedAt: now,
      isActive: habit.isActive,
      currentStreak: newStreak,
      longestStreak: newStreak > habit.longestStreak ? newStreak : habit.longestStreak,
      totalCompletions: habit.totalCompletions + 1,
      lastCompletedAt: now,
      customDays: habit.customDays,
      targetCount: habit.targetCount,
    );
  }

  Habit _markHabitAsUncompleted(Habit habit) {
    return Habit(
      id: habit.id,
      userId: habit.userId,
      title: habit.title,
      description: habit.description,
      category: habit.category,
      frequency: habit.frequency,
      createdAt: habit.createdAt,
      updatedAt: DateTime.now(),
      isActive: habit.isActive,
      currentStreak: habit.currentStreak - 1 < 0 ? 0 : habit.currentStreak - 1,
      longestStreak: habit.longestStreak,
      totalCompletions: habit.totalCompletions - 1 < 0 ? 0 : habit.totalCompletions - 1,
      lastCompletedAt: null, // Reset completion for today
      customDays: habit.customDays,
      targetCount: habit.targetCount,
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
}