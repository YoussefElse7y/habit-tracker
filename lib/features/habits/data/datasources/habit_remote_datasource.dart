
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/habit_model.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';

abstract class HabitRemoteDataSource {
  Future<HabitModel> createHabit(HabitModel habit);
  Future<List<HabitModel>> getAllHabits(String userId);
  Future<List<HabitModel>> getActiveHabits(String userId);
  Future<List<HabitModel>> getHabitsByCategory(String userId, HabitCategory category);
  Future<HabitModel> getHabitById(String habitId);
  Future<HabitModel> updateHabit(HabitModel habit);
  Future<void> deleteHabit(String habitId);
  Future<Map<DateTime, bool>> getHabitHistory(String habitId, DateTime startDate, DateTime endDate);
  Future<List<HabitModel>> getTodaysHabits(String userId);
  Future<HabitStats> getHabitStats(String userId);
  Stream<List<HabitModel>> watchAllHabits(String userId);
  Stream<List<HabitModel>> watchTodaysHabits(String userId);
}

class HabitRemoteDataSourceImpl implements HabitRemoteDataSource {
  final FirebaseFirestore firestore;

  HabitRemoteDataSourceImpl({required this.firestore});

  @override
  Future<HabitModel> createHabit(HabitModel habit) async {
    try {
      final habitDoc = firestore.collection(AppConstants.habitsCollection).doc(habit.id);
      
      await habitDoc.set(habit.toFirestore());
      
      // Return the created habit
      return habit;
    } catch (e) {
      throw ServerException('Failed to create habit: ${e.toString()}');
    }
  }

  @override
  Future<List<HabitModel>> getAllHabits(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection(AppConstants.habitsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get habits: ${e.toString()}');
    }
  }

  @override
  Future<List<HabitModel>> getActiveHabits(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection(AppConstants.habitsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get active habits: ${e.toString()}');
    }
  }

  @override
  Future<List<HabitModel>> getHabitsByCategory(String userId, HabitCategory category) async {
    try {
      final querySnapshot = await firestore
          .collection(AppConstants.habitsCollection)
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category.name)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get habits by category: ${e.toString()}');
    }
  }

  @override
  Future<HabitModel> getHabitById(String habitId) async {
    try {
      final doc = await firestore
          .collection(AppConstants.habitsCollection)
          .doc(habitId)
          .get();

      if (!doc.exists) {
        throw const ServerException('Habit not found');
      }

      return HabitModel.fromFirestore(doc.data()!);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get habit: ${e.toString()}');
    }
  }

  @override
  Future<HabitModel> updateHabit(HabitModel habit) async {
    try {
      final habitDoc = firestore.collection(AppConstants.habitsCollection).doc(habit.id);
      
      // Update with current timestamp
      final updatedHabit = habit.copyWith(updatedAt: DateTime.now());
      
      await habitDoc.update(updatedHabit.toFirestore());
      
      return updatedHabit;
    } catch (e) {
      throw ServerException('Failed to update habit: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    try {
      // Delete the habit document
      await firestore.collection(AppConstants.habitsCollection).doc(habitId).delete();
      
      // Also delete all progress records for this habit
      final progressQuery = await firestore
          .collection(AppConstants.progressCollection)
          .where('habitId', isEqualTo: habitId)
          .get();

      final batch = firestore.batch();
      for (var doc in progressQuery.docs) {
        batch.delete(doc.reference);
      }
      
      if (progressQuery.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      throw ServerException('Failed to delete habit: ${e.toString()}');
    }
  }

  @override
  Future<Map<DateTime, bool>> getHabitHistory(String habitId, DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await firestore
          .collection(AppConstants.progressCollection)
          .where('habitId', isEqualTo: habitId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date')
          .get();

      final Map<DateTime, bool> history = {};
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final completed = data['completed'] as bool? ?? false;
        
        // Normalize date to remove time component
        final normalizedDate = DateTime(date.year, date.month, date.day);
        history[normalizedDate] = completed;
      }

      return history;
    } catch (e) {
      throw ServerException('Failed to get habit history: ${e.toString()}');
    }
  }

  @override
  Future<List<HabitModel>> getTodaysHabits(String userId) async {
    try {
      final today = DateTime.now();
      final dayName = _getDayName(today.weekday).toLowerCase();
      
      final querySnapshot = await firestore
          .collection(AppConstants.habitsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final allHabits = querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc.data()))
          .toList();

      // Filter habits that should show today based on frequency
      return allHabits.where((habit) => habit.shouldShowToday()).toList();
    } catch (e) {
      throw ServerException('Failed to get today\'s habits: ${e.toString()}');
    }
  }

  @override
  Future<HabitStats> getHabitStats(String userId) async {
    try {
      final habitsSnapshot = await firestore
          .collection(AppConstants.habitsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final habits = habitsSnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc.data()))
          .toList();

      if (habits.isEmpty) {
        return const HabitStats(
          totalHabits: 0,
          activeHabits: 0,
          completedToday: 0,
          currentStreaks: 0,
          longestStreak: 0,
          completionRate: 0.0,
        );
      }

      final totalHabits = habits.length;
      final activeHabits = habits.where((h) => h.isActive).length;
      final completedToday = habits.where((h) => h.isCompletedToday()).length;
      final currentStreaks = habits.map((h) => h.currentStreak).reduce((a, b) => a + b);
      final longestStreak = habits.map((h) => h.longestStreak).reduce((a, b) => a > b ? a : b);
      
      // Calculate completion rate for last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final today = DateTime.now();
      
      double totalPossibleCompletions = 0;
      double actualCompletions = 0;
      
      for (var habit in habits.where((h) => h.isActive)) {
        for (int i = 0; i < 30; i++) {
          final date = today.subtract(Duration(days: i));
          if (date.isAfter(habit.createdAt) || date.isAtSameMomentAs(habit.createdAt)) {
            totalPossibleCompletions++;
          }
        }
        actualCompletions += habit.totalCompletions;
      }
      
      final completionRate = totalPossibleCompletions > 0 
          ? (actualCompletions / totalPossibleCompletions * 100).clamp(0.0, 100.0)
          : 0.0;

      return HabitStats(
        totalHabits: totalHabits,
        activeHabits: activeHabits,
        completedToday: completedToday,
        currentStreaks: currentStreaks,
        longestStreak: longestStreak,
        completionRate: completionRate,
      );
    } catch (e) {
      throw ServerException('Failed to get habit stats: ${e.toString()}');
    }
  }

  @override
  Stream<List<HabitModel>> watchAllHabits(String userId) {
    try {
      return firestore
          .collection(AppConstants.habitsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => HabitModel.fromFirestore(doc.data()))
              .toList());
    } catch (e) {
      throw ServerException('Failed to watch habits: ${e.toString()}');
    }
  }

  @override
  Stream<List<HabitModel>> watchTodaysHabits(String userId) {
    try {
      return firestore
          .collection(AppConstants.habitsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            final allHabits = snapshot.docs
                .map((doc) => HabitModel.fromFirestore(doc.data()))
                .toList();
            
            // Filter for today's habits
            return allHabits.where((habit) => habit.shouldShowToday()).toList();
          });
    } catch (e) {
      throw ServerException('Failed to watch today\'s habits: ${e.toString()}');
    }
  }

  // Helper method to get day name from weekday number
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }
}