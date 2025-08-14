
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/habit.dart';

abstract class HabitRepository {
  // Create new habit
  Future<Either<Failure, Habit>> createHabit(Habit habit);

  // Get all habits for current user
  Future<Either<Failure, List<Habit>>> getAllHabits();

  // Get active habits only
  Future<Either<Failure, List<Habit>>> getActiveHabits();

  // Get habits by category
  Future<Either<Failure, List<Habit>>> getHabitsByCategory(HabitCategory category);

  // Get single habit by ID
  Future<Either<Failure, Habit>> getHabitById(String habitId);

  // Update existing habit
  Future<Either<Failure, Habit>> updateHabit(Habit habit);

  // Delete habit
  Future<Either<Failure, void>> deleteHabit(String habitId);

  // Mark habit as completed for today
  Future<Either<Failure, Habit>> completeHabit(String habitId);

  // Undo habit completion for today
  Future<Either<Failure, Habit>> uncompleteHabit(String habitId);

  // Get habit completion history (for charts)
  Future<Either<Failure, Map<DateTime, bool>>> getHabitHistory({
    required String habitId,
    required DateTime startDate,
    required DateTime endDate,
  });

  // Get habits scheduled for today
  Future<Either<Failure, List<Habit>>> getTodaysHabits();

  // Get user's habit statistics
  Future<Either<Failure, HabitStats>> getHabitStats();

  // Pause/Resume habit
  Future<Either<Failure, Habit>> toggleHabitActive(String habitId);

  // Stream of all habits (real-time updates)
  Stream<Either<Failure, List<Habit>>> watchAllHabits();

  // Stream of today's habits
  Stream<Either<Failure, List<Habit>>> watchTodaysHabits();
}

// Helper class for habit statistics
class HabitStats {
  final int totalHabits;
  final int activeHabits;
  final int completedToday;
  final int currentStreaks;
  final int longestStreak;
  final double completionRate; // Percentage

  const HabitStats({
    required this.totalHabits,
    required this.activeHabits,
    required this.completedToday,
    required this.currentStreaks,
    required this.longestStreak,
    required this.completionRate,
  });
}