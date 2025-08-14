
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/habit.dart';
import '../repositories/habit_repository.dart';

class CompleteHabit implements UseCase<Habit, CompleteHabitParams> {
  final HabitRepository repository;

  CompleteHabit(this.repository);

  @override
  Future<Either<Failure, Habit>> call(CompleteHabitParams params) async {
    // Input validation
    if (params.habitId.isEmpty) {
      return const Left(ValidationFailure('Habit ID cannot be empty'));
    }

    // Get the current habit to check its state
    final habitResult = await repository.getHabitById(params.habitId);
    
    return await habitResult.fold(
      (failure) async => Left(failure), // Habit not found or other error
      (habit) async {
        // Business rules validation
        final validationError = _validateHabitCompletion(habit);
        if (validationError != null) {
          return Left(ValidationFailure(validationError));
        }

        // Check if already completed today
        if (habit.isCompletedToday()) {
          return const Left(ValidationFailure(
            'This habit has already been completed today!'
          ));
        }

        // Calculate updated habit with new completion
        final updatedHabit = _calculateCompletionUpdate(habit);

        // Save the updated habit
        return await repository.updateHabit(updatedHabit);
      },
    );
  }

  String? _validateHabitCompletion(Habit habit) {
    // Check if habit is active
    if (!habit.isActive) {
      return 'Cannot complete inactive habit';
    }

    // Check if habit should be shown today based on frequency
    if (!habit.shouldShowToday()) {
      return 'This habit is not scheduled for today';
    }

    return null; // All validations passed
  }

  Habit _calculateCompletionUpdate(Habit habit) {
    final now = DateTime.now();
    
    // Calculate new streak
    final newCurrentStreak = _calculateNewStreak(habit, now);
    
    // Update longest streak if current streak is higher
    final newLongestStreak = newCurrentStreak > habit.longestStreak 
        ? newCurrentStreak 
        : habit.longestStreak;

    // Create updated habit with new completion data
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
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      totalCompletions: habit.totalCompletions + 1,
      lastCompletedAt: now,
      customDays: habit.customDays,
      targetCount: habit.targetCount,
    );
  }

  int _calculateNewStreak(Habit habit, DateTime completionDate) {
    // If this is the first completion ever
    if (habit.lastCompletedAt == null) {
      return 1;
    }

    final lastCompleted = habit.lastCompletedAt!;
    final daysDifference = _daysBetween(lastCompleted, completionDate);

    switch (habit.frequency) {
      case HabitFrequency.daily:
        if (daysDifference == 1) {
          // Consecutive day - increment streak
          return habit.currentStreak + 1;
        } else if (daysDifference == 0) {
          // Same day (shouldn't happen due to validation, but just in case)
          return habit.currentStreak;
        } else {
          // Gap in streak - reset to 1
          return 1;
        }

      case HabitFrequency.weekly:
        // For weekly habits, check if it's within the same week or next week
        if (daysDifference <= 7) {
          return habit.currentStreak + 1;
        } else {
          return 1;
        }

      case HabitFrequency.monthly:
        // For monthly habits, check if it's within the same month or next month
        if (completionDate.month == lastCompleted.month + 1 ||
            (completionDate.month == lastCompleted.month && completionDate.year == lastCompleted.year)) {
          return habit.currentStreak + 1;
        } else {
          return 1;
        }

      case HabitFrequency.custom:
        // For custom habits, just increment if within reasonable time
        if (daysDifference <= 7) {
          return habit.currentStreak + 1;
        } else {
          return 1;
        }
    }
  }

  int _daysBetween(DateTime date1, DateTime date2) {
    // Calculate days between two dates (ignoring time)
    final day1 = DateTime(date1.year, date1.month, date1.day);
    final day2 = DateTime(date2.year, date2.month, date2.day);
    return day2.difference(day1).inDays;
  }
}

// Parameters class for complete habit use case
class CompleteHabitParams {
  final String habitId;

  const CompleteHabitParams({
    required this.habitId,
  });
}