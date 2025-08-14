
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/constants/app_constants.dart';
import '../entities/habit.dart';
import '../repositories/habit_repository.dart';

class AddHabit implements UseCase<Habit, AddHabitParams> {
  final HabitRepository repository;

  AddHabit(this.repository);

  @override
  Future<Either<Failure, Habit>> call(AddHabitParams params) async {
    // Input validation
    final validationResult = _validateInput(params);
    if (validationResult != null) {
      return Left(ValidationFailure(validationResult));
    }

    // Check if user has reached habit limit
    final habitsResult = await repository.getAllHabits();
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
        return await repository.createHabit(habit);
      },
    );

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