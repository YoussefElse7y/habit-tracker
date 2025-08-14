import 'package:equatable/equatable.dart';
import '../../domain/entities/goal.dart';

abstract class GoalsState extends Equatable {
  const GoalsState();

  @override
  List<Object?> get props => [];
}

class GoalsInitial extends GoalsState {}

class GoalsLoading extends GoalsState {}

class GoalsLoaded extends GoalsState {
  final List<Goal> goals;

  const GoalsLoaded({required this.goals});

  @override
  List<Object?> get props => [goals];
}

class GoalsEmpty extends GoalsState {
  final String message;

  const GoalsEmpty({required this.message});

  @override
  List<Object?> get props => [message];
}

class GoalAdded extends GoalsState {
  final Goal goal;
  final List<Goal> updatedGoals;

  const GoalAdded({
    required this.goal,
    required this.updatedGoals,
  });

  @override
  List<Object?> get props => [goal, updatedGoals];
}

class GoalUpdated extends GoalsState {
  final Goal goal;
  final List<Goal> updatedGoals;

  const GoalUpdated({
    required this.goal,
    required this.updatedGoals,
  });

  @override
  List<Object?> get props => [goal, updatedGoals];
}

class GoalDeleted extends GoalsState {
  final String goalId;
  final List<Goal> updatedGoals;

  const GoalDeleted({
    required this.goalId,
    required this.updatedGoals,
  });

  @override
  List<Object?> get props => [goalId, updatedGoals];
}

class GoalsError extends GoalsState {
  final String message;

  const GoalsError({required this.message});

  @override
  List<Object?> get props => [message];
}