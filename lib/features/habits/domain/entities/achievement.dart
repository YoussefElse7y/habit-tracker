// File: features/habits/domain/entities/achievement.dart

import 'package:equatable/equatable.dart';

enum AchievementType {
  streak,      // Streak-based achievements
  completion,  // Completion-based achievements
  milestone,   // Milestone-based achievements
  special,     // Special event achievements
}

enum AchievementTier {
  bronze,   // Basic achievements
  silver,   // Intermediate achievements
  gold,     // Advanced achievements
  platinum, // Expert achievements
  diamond,  // Master achievements
}

class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final AchievementType type;
  final AchievementTier tier;
  final int requirement; // What's needed to unlock (e.g., 7 days for streak)
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int points; // Points awarded for unlocking
  final String? category; // Optional category (e.g., "Health", "Productivity")

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.type,
    required this.tier,
    required this.requirement,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.points,
    this.category,
  });

  // Create a copy with updated fields
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    AchievementType? type,
    AchievementTier? tier,
    int? requirement,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? points,
    String? category,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      type: type ?? this.type,
      tier: tier ?? this.tier,
      requirement: requirement ?? this.requirement,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      points: points ?? this.points,
      category: category ?? this.category,
    );
  }

  // Check if achievement can be unlocked based on current progress
  bool canUnlock(int currentProgress) {
    return !isUnlocked && currentProgress >= requirement;
  }

  // Get achievement color based on tier
  String get tierColor {
    switch (tier) {
      case AchievementTier.bronze:
        return '#CD7F32'; // Bronze color
      case AchievementTier.silver:
        return '#C0C0C0'; // Silver color
      case AchievementTier.gold:
        return '#FFD700'; // Gold color
      case AchievementTier.platinum:
        return '#E5E4E2'; // Platinum color
      case AchievementTier.diamond:
        return '#B9F2FF'; // Diamond color
    }
  }

  // Get achievement emoji based on type
  String get typeEmoji {
    switch (type) {
      case AchievementType.streak:
        return '🔥';
      case AchievementType.completion:
        return '✅';
      case AchievementType.milestone:
        return '🎯';
      case AchievementType.special:
        return '⭐';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        iconName,
        type,
        tier,
        requirement,
        isUnlocked,
        unlockedAt,
        points,
        category,
      ];
}