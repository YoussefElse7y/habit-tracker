// File: features/habits/data/models/user_stats_model.dart

import '../../domain/entities/user_stats.dart';

class UserStatsModel extends UserStats {
  const UserStatsModel({
    required super.userId,
    super.totalPoints = 0,
    super.currentLevel = 1,
    super.totalHabits = 0,
    super.activeHabits = 0,
    super.totalCompletions = 0,
    super.currentStreak = 0,
    super.longestStreak = 0,
    super.totalAchievements = 0,
    super.unlockedAchievements = 0,
    required super.lastActivity,
    super.categoryStats = const {},
    super.weeklyProgress = const {},
    super.monthlyProgress = const {},
  });

  factory UserStatsModel.fromFirestore(Map<String, dynamic> doc) {
    return UserStatsModel(
      userId: doc['userId'] ?? '',
      totalPoints: doc['totalPoints'] ?? 0,
      currentLevel: doc['currentLevel'] ?? 1,
      totalHabits: doc['totalHabits'] ?? 0,
      activeHabits: doc['activeHabits'] ?? 0,
      totalCompletions: doc['totalCompletions'] ?? 0,
      currentStreak: doc['currentStreak'] ?? 0,
      longestStreak: doc['longestStreak'] ?? 0,
      totalAchievements: doc['totalAchievements'] ?? 0,
      unlockedAchievements: doc['unlockedAchievements'] ?? 0,
      lastActivity: _parseDateTime(doc['lastActivity']) ?? DateTime.now(),
      categoryStats: _parseMap(doc['categoryStats']),
      weeklyProgress: _parseMap(doc['weeklyProgress']),
      monthlyProgress: _parseMap(doc['monthlyProgress']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'currentLevel': currentLevel,
      'totalHabits': totalHabits,
      'activeHabits': activeHabits,
      'totalCompletions': totalCompletions,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalAchievements': totalAchievements,
      'unlockedAchievements': unlockedAchievements,
      'lastActivity': lastActivity.toIso8601String(),
      'categoryStats': categoryStats,
      'weeklyProgress': weeklyProgress,
      'monthlyProgress': monthlyProgress,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'currentLevel': currentLevel,
      'totalHabits': totalHabits,
      'activeHabits': activeHabits,
      'totalCompletions': totalCompletions,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalAchievements': totalAchievements,
      'unlockedAchievements': unlockedAchievements,
      'lastActivity': lastActivity.toIso8601String(),
      'categoryStats': categoryStats,
      'weeklyProgress': weeklyProgress,
      'monthlyProgress': monthlyProgress,
    };
  }

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      userId: json['userId'] ?? '',
      totalPoints: json['totalPoints'] ?? 0,
      currentLevel: json['currentLevel'] ?? 1,
      totalHabits: json['totalHabits'] ?? 0,
      activeHabits: json['activeHabits'] ?? 0,
      totalCompletions: json['totalCompletions'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalAchievements: json['totalAchievements'] ?? 0,
      unlockedAchievements: json['unlockedAchievements'] ?? 0,
      lastActivity: _parseDateTime(json['lastActivity']) ?? DateTime.now(),
      categoryStats: _parseMap(json['categoryStats']),
      weeklyProgress: _parseMap(json['weeklyProgress']),
      monthlyProgress: _parseMap(json['monthlyProgress']),
    );
  }

  UserStatsModel copyWith({
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
    return UserStatsModel(
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

  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;

    if (dateValue is DateTime) {
      return dateValue;
    }

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (_) {
        return null;
      }
    }

    if (dateValue.runtimeType.toString().contains('Timestamp')) {
      return dateValue.toDate();
    }

    return null;
  }

  static Map<String, int> _parseMap(dynamic mapValue) {
    if (mapValue == null) return {};

    if (mapValue is Map) {
      final Map<String, int> result = {};
      mapValue.forEach((key, value) {
        if (key is String && value is int) {
          result[key] = value;
        }
      });
      return result;
    }

    return {};
  }
}
