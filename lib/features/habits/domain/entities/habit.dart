
import 'package:equatable/equatable.dart';

enum HabitFrequency {
  daily,
  weekly,
  monthly,
  custom,
}

enum HabitCategory {
  health,
  productivity,
  learning,
  social,
  personal,
  finance,
}

class Habit extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final HabitCategory category;
  final HabitFrequency frequency;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final DateTime? lastCompletedAt;
  final List<String> customDays;
  final int targetCount;

  const Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    this.frequency = HabitFrequency.daily,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCompletions = 0,
    this.lastCompletedAt,
    this.customDays = const [],
    this.targetCount = 1,
  });

  // Helper method to check if habit should be shown today
  bool shouldShowToday() {
    if (!isActive) return false;
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
        if (customDays.isEmpty) return true;
        final dayName = _getDayName(weekday);
        return customDays.contains(dayName.toLowerCase());
      case HabitFrequency.monthly:
        return now.day == 1; 
      case HabitFrequency.custom:
        return customDays.isNotEmpty;
    }
  }

  bool isCompletedToday() {
    if (lastCompletedAt == null) return false;
    
    final now = DateTime.now();
    final lastCompleted = lastCompletedAt!;
    
    return now.year == lastCompleted.year &&
           now.month == lastCompleted.month &&
           now.day == lastCompleted.day;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Monday';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        category,
        frequency,
        createdAt,
        updatedAt,
        isActive,
        currentStreak,
        longestStreak,
        totalCompletions,
        lastCompletedAt,
        customDays,
        targetCount,
      ];
}