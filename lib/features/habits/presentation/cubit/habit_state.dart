// File: features/habits/presentation/cubit/habit_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';

abstract class HabitState extends Equatable {
  const HabitState();

  @override
  List<Object?> get props => [];
}

// Initial state - app just started, no habits loaded yet
class HabitInitial extends HabitState {
  const HabitInitial();
}

// Loading states - different operations in progress
class HabitLoading extends HabitState {
  const HabitLoading();
}

class HabitAddingLoading extends HabitState {
  const HabitAddingLoading();
}

class HabitCompletingLoading extends HabitState {
  final String habitId;
  
  const HabitCompletingLoading(this.habitId);
  
  @override
  List<Object?> get props => [habitId];
}

class HabitDeletingLoading extends HabitState {
  final String habitId;
  
  const HabitDeletingLoading(this.habitId);
  
  @override
  List<Object?> get props => [habitId];
}

// Success states - operations completed successfully
class HabitLoaded extends HabitState {
  final List<Habit> habits;
  
  const HabitLoaded(this.habits);
  
  @override
  List<Object?> get props => [habits];
}

class HabitTodayLoaded extends HabitState {
  final List<Habit> todaysHabits;
  
  const HabitTodayLoaded(this.todaysHabits);
  
  @override
  List<Object?> get props => [todaysHabits];
}

class HabitAddSuccess extends HabitState {
  final Habit addedHabit;
  final String message;
  
  const HabitAddSuccess(this.addedHabit, {this.message = 'Habit added successfully!'});
  
  @override
  List<Object?> get props => [addedHabit, message];
}

class HabitCompleteSuccess extends HabitState {
  final Habit completedHabit;
  final String message;
  
  const HabitCompleteSuccess(this.completedHabit, {this.message = 'Great job! Keep the streak going!'});
  
  @override
  List<Object?> get props => [completedHabit, message];
}

class HabitUncompleteSuccess extends HabitState {
  final Habit uncompletedHabit;
  final String message;
  
  const HabitUncompleteSuccess(this.uncompletedHabit, {this.message = 'Habit unmarked for today'});
  
  @override
  List<Object?> get props => [uncompletedHabit, message];
}

class HabitUpdateSuccess extends HabitState {
  final Habit updatedHabit;
  final String message;
  
  const HabitUpdateSuccess(this.updatedHabit, {this.message = 'Habit updated successfully!'});
  
  @override
  List<Object?> get props => [updatedHabit, message];
}

class HabitDeleteSuccess extends HabitState {
  final String deletedHabitId;
  final String message;
  
  const HabitDeleteSuccess(this.deletedHabitId, {this.message = 'Habit deleted successfully!'});
  
  @override
  List<Object?> get props => [deletedHabitId, message];
}

class HabitToggleActiveSuccess extends HabitState {
  final Habit toggledHabit;
  final String message;
  
  const HabitToggleActiveSuccess(this.toggledHabit, {required this.message});
  
  @override
  List<Object?> get props => [toggledHabit, message];
}

// Statistics and History states
class HabitStatsLoaded extends HabitState {
  final HabitStats stats;
  
  const HabitStatsLoaded(this.stats);
  
  @override
  List<Object?> get props => [stats];
}

class HabitHistoryLoaded extends HabitState {
  final String habitId;
  final Map<DateTime, bool> history;
  final DateTime startDate;
  final DateTime endDate;
  
  const HabitHistoryLoaded({
    required this.habitId,
    required this.history,
    required this.startDate,
    required this.endDate,
  });
  
  @override
  List<Object?> get props => [habitId, history, startDate, endDate];
}

// Error states - operations failed
class HabitError extends HabitState {
  final String message;
  
  const HabitError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class HabitAddError extends HabitState {
  final String message;
  
  const HabitAddError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class HabitCompleteError extends HabitState {
  final String habitId;
  final String message;
  
  const HabitCompleteError(this.habitId, this.message);
  
  @override
  List<Object?> get props => [habitId, message];
}

class HabitDeleteError extends HabitState {
  final String habitId;
  final String message;
  
  const HabitDeleteError(this.habitId, this.message);
  
  @override
  List<Object?> get props => [habitId, message];
}

class HabitUpdateError extends HabitState {
  final String habitId;
  final String message;
  
  const HabitUpdateError(this.habitId, this.message);
  
  @override
  List<Object?> get props => [habitId, message];
}

class HabitNetworkError extends HabitState {
  final String message;
  
  const HabitNetworkError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Category-specific states
class HabitCategoryLoaded extends HabitState {
  final HabitCategory category;
  final List<Habit> habits;
  
  const HabitCategoryLoaded(this.category, this.habits);
  
  @override
  List<Object?> get props => [category, habits];
}

// Empty states - when no data is available
class HabitEmpty extends HabitState {
  final String message;
  
  const HabitEmpty({this.message = 'No habits found. Add your first habit to get started!'});
  
  @override
  List<Object?> get props => [message];
}

class HabitTodayEmpty extends HabitState {
  final String message;
  
  const HabitTodayEmpty({this.message = 'No habits scheduled for today. Enjoy your free time!'});
  
  @override
  List<Object?> get props => [message];
}