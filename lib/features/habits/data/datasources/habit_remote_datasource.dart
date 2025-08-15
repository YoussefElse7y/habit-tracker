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
  
  // Cache for better performance
  final Map<String, List<HabitModel>> _habitsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  HabitRemoteDataSourceImpl({required this.firestore});

  // Helper method to check cache validity
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheValidDuration;
  }

  // Helper method to update cache
  void _updateCache(String key, List<HabitModel> habits) {
    _habitsCache[key] = habits;
    _cacheTimestamps[key] = DateTime.now();
  }

  // Helper method to clear cache
  void _clearCache([String? specificKey]) {
    if (specificKey != null) {
      _habitsCache.remove(specificKey);
      _cacheTimestamps.remove(specificKey);
    } else {
      _habitsCache.clear();
      _cacheTimestamps.clear();
    }
  }

  @override
  Future<HabitModel> createHabit(HabitModel habit) async {
    try {
      final habitDoc = firestore.collection(AppConstants.habitsCollection).doc(habit.id);
      
      await habitDoc.set(habit.toFirestore());
      
      // Clear cache to force refresh
      _clearCache();
      
      return habit;
    } catch (e) {
      throw ServerException('Failed to create habit: ${e.toString()}');
    }
  }

  @override
  Future<List<HabitModel>> getAllHabits(String userId) async {
    final cacheKey = 'all_$userId';
    
    // Return cached data if valid
    if (_isCacheValid(cacheKey)) {
      return _habitsCache[cacheKey]!;
    }

    try {
      final querySnapshot = await firestore
          .collection(AppConstants.habitsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: false)
          .get();

      final habits = querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc.data()))
          .toList();
      
      // Update cache
      _updateCache(cacheKey, habits);
      
      return habits;
    } catch (e) {
      throw ServerException('Failed to get habits: ${e.toString()}');
    }
  }

  @override
  Future<List<HabitModel>> getActiveHabits(String userId) async {
    final cacheKey = 'active_$userId';
    
    // Return cached data if valid
    if (_isCacheValid(cacheKey)) {
      return _habitsCache[cacheKey]!;
    }

    try {
      final querySnapshot = await firestore
          .collection(AppConstants.habitsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();

      final habits = querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc.data()))
          .toList();
      
      // Update cache
      _updateCache(cacheKey, habits);
      
      return habits;
    } catch (e) {
      throw ServerException('Failed to get active habits: ${e.toString()}');
    }
  }

  @override
  Future<List<HabitModel>> getHabitsByCategory(String userId, HabitCategory category) async {
    final cacheKey = 'category_${userId}_${category.name}';
    
    // Return cached data if valid
    if (_isCacheValid(cacheKey)) {
      return _habitsCache[cacheKey]!;
    }

    try {
      final querySnapshot = await firestore
          .collection(AppConstants.habitsCollection)
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category.name)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();

      final habits = querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc.data()))
          .toList();
      
      // Update cache
      _updateCache(cacheKey, habits);
      
      return habits;
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
      
      // Clear cache to force refresh
      _clearCache();
      
      return updatedHabit;
    } catch (e) {
      throw ServerException('Failed to update habit: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    try {
      // Use batch for better performance
      final batch = firestore.batch();
      
      // Delete the habit document
      final habitDoc = firestore.collection(AppConstants.habitsCollection).doc(habitId);
      batch.delete(habitDoc);
      
      // Delete all progress records for this habit
      final progressQuery = await firestore
          .collection(AppConstants.progressCollection)
          .where('habitId', isEqualTo: habitId)
          .get();

      for (var doc in progressQuery.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Clear cache to force refresh
      _clearCache();
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
    final cacheKey = 'today_$userId';
    
    // Return cached data if valid (shorter cache for today's habits)
    if (_isCacheValid(cacheKey)) {
      return _habitsCache[cacheKey]!;
    }

    try {
      // Optimized query - get active habits first
      final querySnapshot = await firestore
          .collection(AppConstants.habitsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _updateCache(cacheKey, []);
        return [];
      }

      final allHabits = querySnapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc.data()))
          .toList();

      // Filter habits that should show today based on frequency
      // This filtering is done in memory which is faster
      final todaysHabits = allHabits.where((habit) {
        return _shouldShowHabitToday(habit);
      }).toList();
      
      // Update cache
      _updateCache(cacheKey, todaysHabits);
      
      return todaysHabits;
    } catch (e) {
      throw ServerException('Failed to get today\'s habits: ${e.toString()}');
    }
  }

  // Optimized method to check if habit should show today
  bool _shouldShowHabitToday(HabitModel habit) {
    if (!habit.isActive) return false;
    
    final today = DateTime.now();
    final todayWeekday = today.weekday;
    
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return true;
      
      case HabitFrequency.weekly:
        // Assuming weekly habits show once per week on a specific day
        // You can customize this logic based on your requirements
        return true;
      
      case HabitFrequency.custom:
        if (habit.customDays?.isEmpty ?? true) return false;
        
        final dayName = _getDayName(todayWeekday).toLowerCase();
        return habit.customDays!.contains(dayName);
      
      default:
        return false;
    }
  }

  @override
  Future<HabitStats> getHabitStats(String userId) async {
    try {
      // Get habits from cache or database
      final habits = await getAllHabits(userId);

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
      
      // Get today's completion status more efficiently
      final todaysHabits = habits.where((h) => _shouldShowHabitToday(h)).toList();
      final completedToday = todaysHabits.where((h) => h.isCompletedToday()).length;
      
      final currentStreaks = habits
          .map((h) => h.currentStreak)
          .fold<int>(0, (sum, streak) => sum + streak);
      
      final longestStreak = habits
          .map((h) => h.longestStreak)
          .fold<int>(0, (max, streak) => streak > max ? streak : max);
      
      // Calculate completion rate for last 30 days
      final now = DateTime.now();
      double totalPossibleCompletions = 0;
      double actualCompletions = 0;
      
      for (var habit in habits.where((h) => h.isActive)) {
        for (int i = 0; i < 30; i++) {
          final date = now.subtract(Duration(days: i));
          if (date.isAfter(habit.createdAt) || date.isAtSameMomentAs(habit.createdAt)) {
            if (_shouldShowHabitToday(habit)) {
              totalPossibleCompletions++;
            }
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
          .map((snapshot) {
            final habits = snapshot.docs
                .map((doc) => HabitModel.fromFirestore(doc.data()))
                .toList();
            
            _updateCache('all_$userId', habits);
            
            return habits;
          });
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
            
            final todaysHabits = allHabits
                .where((habit) => _shouldShowHabitToday(habit))
                .toList();
            
            _updateCache('today_$userId', todaysHabits);
            
            return todaysHabits;
          });
    } catch (e) {
      throw ServerException('Failed to watch today\'s habits: ${e.toString()}');
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'monday', 'tuesday', 'wednesday', 'thursday',
      'friday', 'saturday', 'sunday'
    ];
    return days[weekday - 1];
  }

  void clearAllCaches() {
    _clearCache();
  }
}