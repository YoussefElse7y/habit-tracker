
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/constants/app_constants.dart';
import '../entities/habit.dart';
import '../repositories/habit_repository.dart';
import '../repositories/achievement_repository.dart';

class AddHabit implements UseCase<Habit, AddHabitParams> {
  final HabitRepository habitRepository;
  final AchievementRepository achievementRepository;

  AddHabit({
    required this.habitRepository,
    required this.achievementRepository,
  });

  @override
  Future<Either<Failure, Habit>> call(AddHabitParams params) async {
    // Input validation
    final validationResult = _validateInput(params);
    if (validationResult != null) {
      return Left(ValidationFailure(validationResult));
    }

    // Check if user has reached habit limit
    final habitsResult = await habitRepository.getAllHabits();
    return await habitsResult.fold(
      (failure) async => Left(failure), // Return the failure from getting habits
      (habits) async {
        // Check habit limit
        if (habits.length >= AppConstants.maxHabitsPerUser) {
          return const Left(ValidationFailure(
            'You have reached the maximum limit of habits. Please delete some habits first.',
          ));
        }

        // Create habit entity
        final habit = Habit(
          id: _generateHabitId(),
          userId: params.userId,
          title: params.title.trim(),
          description: params.description?.trim(),
          category: params.category,
          frequency: params.frequency,
          customDays: params.customDays,
          targetCount: params.targetCount,
          createdAt: DateTime.now(),
        );

        // Save to repository
        final habitResult = await habitRepository.createHabit(habit);
        
        return await habitResult.fold(
          (failure) async => Left(failure),
          (createdHabit) async {
            // Update user stats after creating habit
            await _updateUserStatsAfterHabitCreation(params.userId, habits.length + 1);
            
            // Check for achievements (like "First Step")
            await _checkAchievementsAfterHabitCreation(params.userId, habits.length + 1);
            
            return createdHabit;
          },
        );
      },
    );
  }

  /// Update user stats after creating a new habit
  Future<void> _updateUserStatsAfterHabitCreation(String userId, int newTotalHabits) async {
    try {
      await achievementRepository.updateUserStats(userId, {
        'totalHabits': newTotalHabits,
        'activeHabits': newTotalHabits, // New habits are active by default
        'lastActivity': DateTime.now(),
      });
    } catch (e) {
      // Log error but don't fail the habit creation
      print('Failed to update user stats: $e');
    }
  }

  /// Check for achievements after creating a new habit
  Future<void> _checkAchievementsAfterHabitCreation(String userId, int totalHabits) async {
    try {
      // Get current user stats to calculate proper progress
      final userStats = await achievementRepository.getUserStats(userId);
      
      // Check for milestone achievements (like "First Step")
      await achievementRepository.checkAndUnlockAchievements(userId, {
        'totalHabits': totalHabits,
        'totalCompletions': userStats.totalCompletions,
        'currentStreak': userStats.currentStreak,
        'longestStreak': userStats.longestStreak,
        'activeHabits': totalHabits,
      });
    } catch (e) {
      // Log error but don't fail the habit creation
      print('Failed to check achievements: $e');
    }
  }

  String? _validateInput(AddHabitParams params) {
    // Check required fields
    if (params.userId.isEmpty) {
      return 'User must be logged in to create habits';
    }

    if (params.title.trim().isEmpty) {
      return 'Habit title cannot be empty';
    }

    // Title length validation
    if (params.title.trim().length < 3) {
      return 'Habit title must be at least 3 characters long';
    }

    if (params.title.trim().length > 100) {
      return 'Habit title cannot exceed 100 characters';
    }

    // Description validation (optional field)
    if (params.description != null && params.description!.length > 500) {
      return 'Habit description cannot exceed 500 characters';
    }

    // Target count validation
    if (params.targetCount < 1) {
      return 'Target count must be at least 1';
    }

    if (params.targetCount > 10) {
      return 'Target count cannot exceed 10 per day';
    }

    // Custom days validation for weekly habits
    if (params.frequency == HabitFrequency.weekly && params.customDays.isNotEmpty) {
      final validDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      for (String day in params.customDays) {
        if (!validDays.contains(day.toLowerCase())) {
          return 'Invalid day: $day';
        }
      }
    }

    return null; // All validations passed
  }

  String _generateHabitId() {
    // Generate unique ID (in real app, this might be handled by Firebase)
    return 'habit_${DateTime.now().millisecondsSinceEpoch}';
  }
}

// Parameters class for add habit use case
class AddHabitParams {
  final String userId;
  final String title;
  final String? description;
  final HabitCategory category;
  final HabitFrequency frequency;
  final List<String> customDays;
  final int targetCount;

  const AddHabitParams({
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    this.frequency = HabitFrequency.daily,
    this.customDays = const [],
    this.targetCount = 1,
  });
}