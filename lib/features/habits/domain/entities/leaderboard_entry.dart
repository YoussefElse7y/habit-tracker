// File: features/habits/domain/entities/leaderboard_entry.dart

import 'package:equatable/equatable.dart';

class LeaderboardEntry extends Equatable {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final int rank;
  final int totalPoints;
  final int currentLevel;
  final int totalCompletions;
  final int currentStreak;
  final int longestStreak;
  final int unlockedAchievements;
  final DateTime lastActivity;
  final String? category; // For category-specific leaderboards
  final Map<String, dynamic> additionalStats; // Flexible additional statistics

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.rank,
    required this.totalPoints,
    required this.currentLevel,
    required this.totalCompletions,
    required this.currentStreak,
    required this.longestStreak,
    required this.unlockedAchievements,
    required this.lastActivity,
    this.category,
    this.additionalStats = const {},
  });

  // Create a copy with updated fields
  LeaderboardEntry copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    int? rank,
    int? totalPoints,
    int? currentLevel,
    int? totalCompletions,
    int? currentStreak,
    int? longestStreak,
    int? unlockedAchievements,
    DateTime? lastActivity,
    String? category,
    Map<String, dynamic>? additionalStats,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rank: rank ?? this.rank,
      totalPoints: totalPoints ?? this.totalPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      lastActivity: lastActivity ?? this.lastActivity,
      category: category ?? this.category,
      additionalStats: additionalStats ?? this.additionalStats,
    );
  }

  // Get display name (prefer displayName over username)
  String get effectiveDisplayName => displayName ?? username;

  // Get rank emoji based on position
  String get rankEmoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      case 4:
      case 5:
        return '🏅';
      default:
        return '🎯';
    }
  }

  // Get level title
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

  // Get level emoji
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

  // Get activity status
  String get activityStatus {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);
    
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
    return '${(difference.inDays / 30).floor()} months ago';
  }

  // Get activity status emoji
  String get activityStatusEmoji {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);
    
    if (difference.inDays == 0) return '🟢';
    if (difference.inDays <= 3) return '🟡';
    if (difference.inDays <= 7) return '🟠';
    return '🔴';
  }

  // Check if user is currently active (within last 24 hours)
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return now.difference(lastActivity).inDays == 0;
  }

  // Get completion rate (if total habits data is available)
  double? get completionRate {
    final totalHabits = additionalStats['totalHabits'] as int?;
    if (totalHabits == null || totalHabits == 0) return null;
    return (totalCompletions / totalHabits) * 100;
  }

  // Get achievement rate (if total achievements data is available)
  double? get achievementRate {
    final totalAchievements = additionalStats['totalAchievements'] as int?;
    if (totalAchievements == null || totalAchievements == 0) return null;
    return (unlockedAchievements / totalAchievements) * 100;
  }

  // Get category-specific stats
  int? getCategoryCompletions(String category) {
    final categoryStats = additionalStats['categoryStats'] as Map<String, dynamic>?;
    return categoryStats?[category] as int?;
  }

  // Get weekly progress
  int? getWeeklyProgress() {
    return additionalStats['weeklyProgress'] as int?;
  }

  // Get monthly progress
  int? getMonthlyProgress() {
    return additionalStats['monthlyProgress'] as int?;
  }

  // Check if this is a top performer
  bool get isTopPerformer => rank <= 10;

  // Check if this is a podium finisher
  bool get isPodiumFinisher => rank <= 3;

  // Get rank suffix
  String get rankSuffix {
    if (rank >= 11 && rank <= 13) return 'th';
    switch (rank % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  // Get formatted rank
  String get formattedRank => '$rank$rankSuffix';

  @override
  List<Object?> get props => [
        userId,
        username,
        displayName,
        avatarUrl,
        rank,
        totalPoints,
        currentLevel,
        totalCompletions,
        currentStreak,
        longestStreak,
        unlockedAchievements,
        lastActivity,
        category,
        additionalStats,
      ];
}