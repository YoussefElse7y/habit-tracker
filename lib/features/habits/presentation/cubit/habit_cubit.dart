// File: features/habits/presentation/cubit/habit_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/base_cubit.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/usecases/add_habit.dart';
import '../../domain/usecases/complete_habit.dart';
import 'habit_state.dart';

class HabitCubit extends BaseCubit<HabitState> {
  // Inject use cases - these handle business logic
  final AddHabit addHabitUseCase;
  final CompleteHabit completeHabitUseCase;
  final HabitRepository habitRepository; // For simpler operations

  HabitCubit({
    required this.addHabitUseCase,
    required this.completeHabitUseCase,
    required this.habitRepository,
  }) : super(const HabitInitial());

  // Cache current habits for better performance
  List<Habit> _currentHabits = [];
  List<Habit> _todaysHabits = [];

  // Public getters for cached data
  List<Habit> get currentHabits => List.unmodifiable(_currentHabits);
  List<Habit> get todaysHabits => List.unmodifiable(_todaysHabits);

  /// Load all habits for the current user
  Future<void> loadAllHabits() async {
    // Don't show loading if we already have habits (for better UX)
    if (_currentHabits.isEmpty) {
      emit(const HabitLoading());
    }

    final result = await habitRepository.getAllHabits();

    result.fold(
      (failure) {
        // If we have cached habits, keep showing them with an error message
        if (_currentHabits.isNotEmpty) {
          emit(HabitNetworkError('Failed to sync habits: ${failure.message}'));
        } else {
          emit(HabitError(failure.message));
        }
      },
      (habits) {
        _currentHabits = habits;
        
        if (habits.isEmpty) {
          emit(const HabitEmpty());
        } else {
          emit(HabitLoaded(habits));
        }
      },
    );
  }

  /// Load habits that should be shown today
  Future<void> loadTodaysHabits() async {
    // Show loading only if no today's habits are cached
    if (_todaysHabits.isEmpty) {
      emit(const HabitLoading());
    }

    final result = await habitRepository.getTodaysHabits();

    result.fold(
      (failure) {
        // Fallback to cached data if available
        if (_todaysHabits.isNotEmpty) {
          emit(HabitNetworkError('Failed to sync today\'s habits: ${failure.message}'));
        } else {
          emit(HabitError(failure.message));
        }
      },
      (habits) {
        _todaysHabits = habits;
        
        if (habits.isEmpty) {
          emit(const HabitTodayEmpty());
        } else {
          emit(HabitTodayLoaded(habits));
        }
      },
    );
  }

  /// Load habits by specific category
  Future<void> loadHabitsByCategory(HabitCategory category) async {
    emit(const HabitLoading());

    final result = await habitRepository.getHabitsByCategory(category);

    result.fold(
      (failure) => emit(HabitError(failure.message)),
      (habits) {
        if (habits.isEmpty) {
          emit(HabitEmpty(message: 'No ${category.name} habits found.'));
        } else {
          emit(HabitCategoryLoaded(category, habits));
        }
      },
    );
  }

  /// Add a new habit
  Future<void> addHabit({
    required String userId,
    required String title,
    String? description,
    required HabitCategory category,
    HabitFrequency frequency = HabitFrequency.daily,
    List<String> customDays = const [],
    int targetCount = 1,
  }) async {
    // Validate input before making network call
    if (title.trim().isEmpty) {
      emit(const HabitAddError('Habit title cannot be empty'));
      return;
    }

    if (title.trim().length < 3) {
      emit(const HabitAddError('Habit title must be at least 3 characters long'));
      return;
    }

    // Check habit limit
    if (_currentHabits.length >= AppConstants.maxHabitsPerUser) {
      emit(HabitAddError(
        'You have reached the maximum limit of ${AppConstants.maxHabitsPerUser} habits. Please delete some habits first.',
      ));
      return;
    }

    emit(const HabitAddingLoading());

    final params = AddHabitParams(
      userId: userId,
      title: title,
      description: description,
      category: category,
      frequency: frequency,
      customDays: customDays,
      targetCount: targetCount,
    );

    final result = await addHabitUseCase.call(params);

    result.fold(
      (failure) => emit(HabitAddError(failure.message)),
      (habit) {
        // Update local cache
        _currentHabits.add(habit);
        
        // Update today's habits if the new habit should show today
        if (habit.shouldShowToday()) {
          _todaysHabits.add(habit);
        }

        emit(HabitAddSuccess(habit));
        
        // Immediately update the UI with new data
        emit(HabitLoaded(_currentHabits));
      },
    );
  }

  /// Mark a habit as completed for today - OPTIMIZED VERSION
  Future<void> completeHabit(String habitId) async {
    // Find the habit in our cache
    final habitIndex = _currentHabits.indexWhere((h) => h.id == habitId);
    if (habitIndex == -1) {
      emit(HabitCompleteError(habitId, 'Habit not found'));
      return;
    }

    final habit = _currentHabits[habitIndex];

    // Quick validation
    if (habit.isCompletedToday()) {
      emit(HabitCompleteError(habitId, 'This habit has already been completed today!'));
      return;
    }

    if (!habit.isActive) {
      emit(HabitCompleteError(habitId, 'Cannot complete inactive habit'));
      return;
    }

    // Show loading state immediately
    emit(HabitCompletingLoading(habitId));

    final params = CompleteHabitParams(habitId: habitId);
    final result = await completeHabitUseCase.call(params);

    result.fold(
      (failure) => emit(HabitCompleteError(habitId, failure.message)),
      (updatedHabit) {
        // Update local caches immediately
        _currentHabits[habitIndex] = updatedHabit;
        
        final todayIndex = _todaysHabits.indexWhere((h) => h.id == habitId);
        if (todayIndex != -1) {
          _todaysHabits[todayIndex] = updatedHabit;
        }

        // Show success message with streak info
        final streakMessage = updatedHabit.currentStreak > 1 
            ? 'Awesome! ${updatedHabit.currentStreak} day streak! 🔥'
            : AppConstants.habitCompletedMessage;

        emit(HabitCompleteSuccess(updatedHabit, message: streakMessage));
        
        // Immediately update the UI with new data - no delays
        emit(HabitTodayLoaded(_todaysHabits));
      },
    );
  }

  /// Undo habit completion for today - OPTIMIZED VERSION
  Future<void> uncompleteHabit(String habitId) async {
    final habitIndex = _currentHabits.indexWhere((h) => h.id == habitId);
    if (habitIndex == -1) {
      emit(HabitCompleteError(habitId, 'Habit not found'));
      return;
    }

    final habit = _currentHabits[habitIndex];

    if (!habit.isCompletedToday()) {
      emit(HabitCompleteError(habitId, 'This habit is not completed today'));
      return;
    }

    emit(HabitCompletingLoading(habitId));

    final result = await habitRepository.uncompleteHabit(habitId);

    result.fold(
      (failure) => emit(HabitCompleteError(habitId, failure.message)),
      (updatedHabit) {
        // Update local caches immediately
        _currentHabits[habitIndex] = updatedHabit;
        
        final todayIndex = _todaysHabits.indexWhere((h) => h.id == habitId);
        if (todayIndex != -1) {
          _todaysHabits[todayIndex] = updatedHabit;
        }

        emit(HabitUncompleteSuccess(updatedHabit));
        
        // Immediately update the UI - no delays
        emit(HabitTodayLoaded(_todaysHabits));
      },
    );
  }

  /// Update an existing habit - OPTIMIZED VERSION
  Future<void> updateHabit(Habit updatedHabit) async {
    final habitIndex = _currentHabits.indexWhere((h) => h.id == updatedHabit.id);
    if (habitIndex == -1) {
      emit(HabitUpdateError(updatedHabit.id, 'Habit not found'));
      return;
    }

    emit(const HabitLoading());

    final result = await habitRepository.updateHabit(updatedHabit);

    result.fold(
      (failure) => emit(HabitUpdateError(updatedHabit.id, failure.message)),
      (habit) {
        // Update local caches immediately
        _currentHabits[habitIndex] = habit;
        
        final todayIndex = _todaysHabits.indexWhere((h) => h.id == habit.id);
        if (todayIndex != -1) {
          if (habit.shouldShowToday() && habit.isActive) {
            _todaysHabits[todayIndex] = habit;
          } else {
            _todaysHabits.removeAt(todayIndex);
          }
        } else if (habit.shouldShowToday() && habit.isActive) {
          _todaysHabits.add(habit);
        }

        emit(HabitUpdateSuccess(habit));
        
        // Immediately update the UI - no delays
        emit(HabitLoaded(_currentHabits));
      },
    );
  }

  /// Delete a habit permanently - OPTIMIZED VERSION
  Future<void> deleteHabit(String habitId) async {
    final habitIndex = _currentHabits.indexWhere((h) => h.id == habitId);
    if (habitIndex == -1) {
      emit(HabitDeleteError(habitId, 'Habit not found'));
      return;
    }

    emit(HabitDeletingLoading(habitId));

    final result = await habitRepository.deleteHabit(habitId);

    result.fold(
      (failure) => emit(HabitDeleteError(habitId, failure.message)),
      (_) {
        // Remove from local caches immediately
        _currentHabits.removeAt(habitIndex);
        _todaysHabits.removeWhere((h) => h.id == habitId);

        emit(HabitDeleteSuccess(habitId));
        
        // Immediately update the UI - no delays
        if (_currentHabits.isEmpty) {
          emit(const HabitEmpty());
        } else {
          emit(HabitLoaded(_currentHabits));
        }
      },
    );
  }

  /// Toggle habit active/inactive status - OPTIMIZED VERSION
  Future<void> toggleHabitActive(String habitId) async {
    final habitIndex = _currentHabits.indexWhere((h) => h.id == habitId);
    if (habitIndex == -1) {
      emit(HabitUpdateError(habitId, 'Habit not found'));
      return;
    }
    emit(const HabitLoading());

    final result = await habitRepository.toggleHabitActive(habitId);

    result.fold(
      (failure) => emit(HabitUpdateError(habitId, failure.message)),
      (updatedHabit) {
        // Update local caches immediately
        _currentHabits[habitIndex] = updatedHabit;
        
        // Handle today's habits list
        final todayIndex = _todaysHabits.indexWhere((h) => h.id == habitId);
        if (updatedHabit.isActive && updatedHabit.shouldShowToday()) {
          if (todayIndex == -1) {
            _todaysHabits.add(updatedHabit);
          } else {
            _todaysHabits[todayIndex] = updatedHabit;
          }
        } else if (todayIndex != -1) {
          _todaysHabits.removeAt(todayIndex);
        }

        final message = updatedHabit.isActive ? 'Habit activated' : 'Habit paused';
        emit(HabitToggleActiveSuccess(updatedHabit, message: message));
        
        // Immediately update the UI - no delays
        emit(HabitLoaded(_currentHabits));
      },
    );
  }

  /// Load habit statistics
  Future<void> loadHabitStats() async {
    emit(const HabitLoading());

    final result = await habitRepository.getHabitStats();

    result.fold(
      (failure) => emit(HabitError(failure.message)),
      (stats) => emit(HabitStatsLoaded(stats)),
    );
  }

  /// Load habit history for charts/calendar view
  Future<void> loadHabitHistory({
    required String habitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    emit(const HabitLoading());

    final result = await habitRepository.getHabitHistory(
      habitId: habitId,
      startDate: startDate,
      endDate: endDate,
    );

    result.fold(
      (failure) => emit(HabitError(failure.message)),
      (history) => emit(HabitHistoryLoaded(
        habitId: habitId,
        history: history,
        startDate: startDate,
        endDate: endDate,
      )),
    );
  }

  /// Refresh all data (pull to refresh)
  Future<void> refreshAllData() async {
    await Future.wait([
      loadAllHabits(),
      loadTodaysHabits(),
    ]);
  }

  /// Clear cache and reset to initial state
  void resetState() {
    _currentHabits.clear();
    _todaysHabits.clear();
    emit(const HabitInitial());
  }

  /// Handle network reconnection
  void onNetworkReconnected() {
    // Refresh data when network comes back
    refreshAllData();
  }
}