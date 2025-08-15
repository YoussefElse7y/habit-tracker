// File: features/habits/domain/entities/user_stats.dart

import 'package:equatable/equatable.dart';

class UserStats extends Equatable {
  final String userId;
  final int totalPoints;
  final int currentLevel;
  final int totalHabits;
  final int activeHabits;
  final int totalCompletions;
  final int currentStreak;
  final int longestStreak;
  final int totalAchievements;
  final int unlockedAchievements;
  final DateTime lastActivity;
  final Map<String, int> categoryStats; // Stats per habit category
  final Map<String, int> weeklyProgress; // Weekly completion counts
  final Map<String, int> monthlyProgress; // Monthly completion counts

  const UserStats({
    required this.userId,
    this.totalPoints = 0,
    this.currentLevel = 1,
    this.totalHabits = 0,
    this.activeHabits = 0,
    this.totalCompletions = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalAchievements = 0,
    this.unlockedAchievements = 0,
    required this.lastActivity,
    this.categoryStats = const {},
    this.weeklyProgress = const {},
    this.monthlyProgress = const {},
  });

  // Create a copy with updated fields
  UserStats copyWith({
    String? userId,
    int? totalPoints,
    int? currentLevel,
    int? totalHabits,
    int? activeHabits,
    int? totalCompletions,
    int? currentStreak,
    int? longestStreak,
    int? totalAchievements,
    int? unlockedAchievements,
    DateTime? lastActivity,
    Map<String, int>? categoryStats,
    Map<String, int>? weeklyProgress,
    Map<String, int>? monthlyProgress,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      totalHabits: totalHabits ?? this.totalHabits,
      activeHabits: activeHabits ?? this.activeHabits,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalAchievements: totalAchievements ?? this.totalAchievements,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      lastActivity: lastActivity ?? this.lastActivity,
      categoryStats: categoryStats ?? this.categoryStats,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      monthlyProgress: monthlyProgress ?? this.monthlyProgress,
    );
  }

  // Calculate completion rate
  double get completionRate {
    if (totalHabits == 0) return 0.0;
    return (totalCompletions / totalHabits) * 100;
  }

  // Calculate achievement rate
  double get achievementRate {
    if (totalAchievements == 0) return 0.0;
    return (unlockedAchievements / totalAchievements) * 100;
  }

  // Get points needed for next level
  int get pointsForNextLevel {
    return _calculatePointsForLevel(currentLevel + 1);
  }

  // Get progress to next level (0.0 to 1.0)
  double get levelProgress {
    final currentLevelPoints = _calculatePointsForLevel(currentLevel);
    final nextLevelPoints = _calculatePointsForLevel(currentLevel + 1);
    final pointsInCurrentLevel = totalPoints - currentLevelPoints;
    final pointsNeededForLevel = nextLevelPoints - currentLevelPoints;
    
    if (pointsNeededForLevel <= 0) return 1.0;
    return (pointsInCurrentLevel / pointsNeededForLevel).clamp(0.0, 1.0);
  }

  // Calculate points needed for a specific level
  int _calculatePointsForLevel(int level) {
    // Exponential growth: each level requires more points
    return (100 * (level - 1) * (level - 1)).clamp(0, 10000);
  }

  // Get level title based on current level
  String get levelTitle {
    if (currentLevel < 5) return 'Beginner';
    if (currentLevel < 10) return 'Apprentice';
    if (currentLevel < 20) return 'Practitioner';
    if (currentLevel < 35) return 'Expert';
    if (currentLevel < 50) return 'Master';
    if (currentLevel < 75) return 'Grandmaster';
    if (currentLevel < 100) return 'Legend';
    return 'Mythic';
  }

  // Get level emoji based on current level
  String get levelEmoji {
    if (currentLevel < 5) return '🌱';
    if (currentLevel < 10) return '📚';
    if (currentLevel < 20) return '⚡';
    if (currentLevel < 35) return '🔥';
    if (currentLevel < 50) return '🏆';
    if (currentLevel < 75) return '👑';
    if (currentLevel < 100) return '💎';
    return '🌟';
  }

  // Get best performing category
  String? get bestCategory {
    if (categoryStats.isEmpty) return null;
    
    String bestCategory = '';
    int maxCompletions = 0;
    
    categoryStats.forEach((category, completions) {
      if (completions > maxCompletions) {
        maxCompletions = completions;
        bestCategory = category;
      }
    });
    
    return bestCategory;
  }

  // Get weekly average completions
  double get weeklyAverage {
    if (weeklyProgress.isEmpty) return 0.0;
    
    final total = weeklyProgress.values.fold<int>(0, (sum, count) => sum + count);
    return total / weeklyProgress.length;
  }

  // Get monthly average completions
  double get monthlyAverage {
    if (monthlyProgress.isEmpty) return 0.0;
    
    final total = monthlyProgress.values.fold<int>(0, (sum, count) => sum + count);
    return total / monthlyProgress.length;
  }

  @override
  List<Object?> get props => [
        userId,
        totalPoints,
        currentLevel,
        totalHabits,
        activeHabits,
        totalCompletions,
        currentStreak,
        longestStreak,
        totalAchievements,
        unlockedAchievements,
        lastActivity,
        categoryStats,
        weeklyProgress,
        monthlyProgress,
      ];
}