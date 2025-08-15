// File: features/habits/domain/entities/achievement_progress.dart

import 'package:equatable/equatable.dart';
import 'achievement.dart';

class AchievementProgress extends Equatable {
  final String id;
  final String userId;
  final String achievementId;
  final int currentProgress;
  final int requiredProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final DateTime lastUpdated;
  final Map<String, dynamic> progressData; // Flexible data for different achievement types

  const AchievementProgress({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.currentProgress,
    required this.requiredProgress,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.lastUpdated,
    this.progressData = const {},
  });

  // Create a copy with updated fields
  AchievementProgress copyWith({
    String? id,
    String? userId,
    String? achievementId,
    int? currentProgress,
    int? requiredProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
    DateTime? lastUpdated,
    Map<String, dynamic>? progressData,
  }) {
    return AchievementProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      currentProgress: currentProgress ?? this.currentProgress,
      requiredProgress: requiredProgress ?? this.requiredProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      progressData: progressData ?? this.progressData,
    );
  }

  // Calculate progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (requiredProgress <= 0) return 1.0;
    return (currentProgress / requiredProgress).clamp(0.0, 1.0);
  }

  // Check if achievement can be unlocked
  bool get canUnlock => currentProgress >= requiredProgress && !isUnlocked;

  // Get progress remaining
  int get progressRemaining => (requiredProgress - currentProgress).clamp(0, requiredProgress);

  // Get progress status
  String get progressStatus {
    if (isUnlocked) return 'Unlocked';
    if (canUnlock) return 'Ready to unlock';
    if (currentProgress > 0) return 'In progress';
    return 'Not started';
  }

  // Get progress emoji
  String get progressEmoji {
    if (isUnlocked) return '🏆';
    if (canUnlock) return '✨';
    if (currentProgress > 0) return '🔥';
    return '⏳';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        achievementId,
        currentProgress,
        requiredProgress,
        isUnlocked,
        unlockedAt,
        lastUpdated,
        progressData,
      ];
}