import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/goal.dart';
import 'goals_state.dart';

class GoalsCubit extends Cubit<GoalsState> {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  List<Goal> _currentGoals = [];

  GoalsCubit({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(GoalsInitial());

  List<Goal> get currentGoals => _currentGoals;

  Future<void> loadGoals() async {
    try {
      emit(GoalsLoading());
      
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        emit(const GoalsError(message: 'No user logged in'));
        return;
      }

      final goalsSnapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      if (goalsSnapshot.docs.isEmpty) {
        _currentGoals = [];
        emit(const GoalsEmpty(message: 'No goals found. Create your first goal!'));
        return;
      }

      _currentGoals = goalsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Goal(
          id: doc.id,
          userId: data['userId'] ?? '',
          title: data['title'] ?? '',
          description: data['description'],
          targetValue: data['targetValue'] ?? 1,
          currentValue: data['currentValue'] ?? 0,
          frequency: _parseGoalFrequency(data['frequency']),
          status: _parseGoalStatus(data['status']),
          createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
          updatedAt: data['updatedAt']?.toDate(),
          targetDate: data['targetDate']?.toDate(),
          iconName: data['iconName'],
          colorHex: data['colorHex'],
        );
      }).toList();

      emit(GoalsLoaded(goals: _currentGoals));
    } catch (e) {
      emit(GoalsError(message: 'Failed to load goals: $e'));
    }
  }

  Future<void> addGoal({
    required String title,
    String? description,
    required int targetValue,
    GoalFrequency frequency = GoalFrequency.daily,
    DateTime? targetDate,
    String? iconName,
    String? colorHex,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        emit(const GoalsError(message: 'No user logged in'));
        return;
      }

      final goalData = {
        'userId': currentUser.uid,
        'title': title,
        'description': description,
        'targetValue': targetValue,
        'currentValue': 0,
        'frequency': frequency.name,
        'status': GoalStatus.active.name,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'targetDate': targetDate != null ? Timestamp.fromDate(targetDate) : null,
        'iconName': iconName,
        'colorHex': colorHex,
      };

      final docRef = await _firestore.collection('goals').add(goalData);
      
      final newGoal = Goal(
        id: docRef.id,
        userId: currentUser.uid,
        title: title,
        description: description,
        targetValue: targetValue,
        currentValue: 0,
        frequency: frequency,
        status: GoalStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        targetDate: targetDate,
        iconName: iconName,
        colorHex: colorHex,
      );

      _currentGoals.insert(0, newGoal);
      emit(GoalAdded(goal: newGoal, updatedGoals: List.from(_currentGoals)));
    } catch (e) {
      emit(GoalsError(message: 'Failed to add goal: $e'));
    }
  }

  Future<void> updateGoalProgress(String goalId, int newCurrentValue) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        emit(const GoalsError(message: 'No user logged in'));
        return;
      }

      await _firestore.collection('goals').doc(goalId).update({
        'currentValue': newCurrentValue,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final goalIndex = _currentGoals.indexWhere((goal) => goal.id == goalId);
      if (goalIndex != -1) {
        final updatedGoal = _currentGoals[goalIndex].copyWith(
          currentValue: newCurrentValue,
          updatedAt: DateTime.now(),
        );
        _currentGoals[goalIndex] = updatedGoal;
        emit(GoalUpdated(goal: updatedGoal, updatedGoals: List.from(_currentGoals)));
      }
    } catch (e) {
      emit(GoalsError(message: 'Failed to update goal progress: $e'));
    }
  }

  Future<void> incrementGoalProgress(String goalId) async {
    final goal = _currentGoals.firstWhere((g) => g.id == goalId);
    final newValue = (goal.currentValue + 1).clamp(0, goal.targetValue);
    await updateGoalProgress(goalId, newValue);
  }

  Future<void> decrementGoalProgress(String goalId) async {
    final goal = _currentGoals.firstWhere((g) => g.id == goalId);
    final newValue = (goal.currentValue - 1).clamp(0, goal.targetValue);
    await updateGoalProgress(goalId, newValue);
  }

  Future<void> editGoal({
    required String goalId,
    String? title,
    String? description,
    int? targetValue,
    GoalFrequency? frequency,
    DateTime? targetDate,
    String? iconName,
    String? colorHex,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        emit(const GoalsError(message: 'No user logged in'));
        return;
      }

      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (targetValue != null) updateData['targetValue'] = targetValue;
      if (frequency != null) updateData['frequency'] = frequency.name;
      if (targetDate != null) updateData['targetDate'] = Timestamp.fromDate(targetDate);
      if (iconName != null) updateData['iconName'] = iconName;
      if (colorHex != null) updateData['colorHex'] = colorHex;

      await _firestore.collection('goals').doc(goalId).update(updateData);

      final goalIndex = _currentGoals.indexWhere((goal) => goal.id == goalId);
      if (goalIndex != -1) {
        final currentGoal = _currentGoals[goalIndex];
        final updatedGoal = currentGoal.copyWith(
          title: title ?? currentGoal.title,
          description: description ?? currentGoal.description,
          targetValue: targetValue ?? currentGoal.targetValue,
          frequency: frequency ?? currentGoal.frequency,
          targetDate: targetDate ?? currentGoal.targetDate,
          iconName: iconName ?? currentGoal.iconName,
          colorHex: colorHex ?? currentGoal.colorHex,
          updatedAt: DateTime.now(),
        );
        _currentGoals[goalIndex] = updatedGoal;
        emit(GoalUpdated(goal: updatedGoal, updatedGoals: List.from(_currentGoals)));
      }
    } catch (e) {
      emit(GoalsError(message: 'Failed to edit goal: $e'));
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        emit(const GoalsError(message: 'No user logged in'));
        return;
      }

      await _firestore.collection('goals').doc(goalId).update({
        'status': GoalStatus.cancelled.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _currentGoals.removeWhere((goal) => goal.id == goalId);
      
      if (_currentGoals.isEmpty) {
        emit(const GoalsEmpty(message: 'No goals found. Create your first goal!'));
      } else {
        emit(GoalDeleted(goalId: goalId, updatedGoals: List.from(_currentGoals)));
      }
    } catch (e) {
      emit(GoalsError(message: 'Failed to delete goal: $e'));
    }
  }

  GoalFrequency _parseGoalFrequency(String? frequency) {
    switch (frequency) {
      case 'daily':
        return GoalFrequency.daily;
      case 'weekly':
        return GoalFrequency.weekly;
      case 'monthly':
        return GoalFrequency.monthly;
      case 'custom':
        return GoalFrequency.custom;
      default:
        return GoalFrequency.daily;
    }
  }

  GoalStatus _parseGoalStatus(String? status) {
    switch (status) {
      case 'active':
        return GoalStatus.active;
      case 'completed':
        return GoalStatus.completed;
      case 'paused':
        return GoalStatus.paused;
      case 'cancelled':
        return GoalStatus.cancelled;
      default:
        return GoalStatus.active;
    }
  }
}