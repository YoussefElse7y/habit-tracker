// File: features/habits/presentation/cubit/achievement_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/user_stats.dart';

abstract class AchievementState extends Equatable {
  const AchievementState();

  @override
  List<Object?> get props => [];
}

// Initial state
class AchievementInitial extends AchievementState {
  const AchievementInitial();
}

// Loading states
class AchievementLoading extends AchievementState {
  const AchievementLoading();
}

class AchievementChecking extends AchievementState {
  const AchievementChecking();
}

// Success states
class AchievementLoaded extends AchievementState {
  final List<Achievement> achievements;
  
  const AchievementLoaded(this.achievements);
  
  @override
  List<Object?> get props => [achievements];
}

class UserAchievementsLoaded extends AchievementState {
  final List<Achievement> achievements;
  
  const UserAchievementsLoaded(this.achievements);
  
  @override
  List<Object?> get props => [achievements];
}

class UserStatsLoaded extends AchievementState {
  final UserStats stats;
  
  const UserStatsLoaded(this.stats);
  
  @override
  List<Object?> get props => [stats];
}

class AchievementsUnlocked extends AchievementState {
  final List<Achievement> newAchievements;
  
  const AchievementsUnlocked(this.newAchievements);
  
  @override
  List<Object?> get props => [newAchievements];
}

class AchievementCheckComplete extends AchievementState {
  const AchievementCheckComplete();
}

class PointsAwarded extends AchievementState {
  final int points;
  final String reason;
  final int newTotal;
  
  const PointsAwarded(this.points, this.reason, this.newTotal);
  
  @override
  List<Object?> get props => [points, reason, newTotal];
}

class LevelUpAchieved extends AchievementState {
  final int previousLevel;
  final int newLevel;
  
  const LevelUpAchieved(this.previousLevel, this.newLevel);
  
  @override
  List<Object?> get props => [previousLevel, newLevel];
}

class LeaderboardLoaded extends AchievementState {
  final List<Map<String, dynamic>> leaderboard;
  
  const LeaderboardLoaded(this.leaderboard);
  
  @override
  List<Object?> get props => [leaderboard];
}

class StreakRecoveryOptionsLoaded extends AchievementState {
  final Map<String, dynamic> options;
  
  const StreakRecoveryOptionsLoaded(this.options);
  
  @override
  List<Object?> get props => [options];
}

class StreakRecoveryUsed extends AchievementState {
  const StreakRecoveryUsed();
}

class ChallengesLoaded extends AchievementState {
  final List<Map<String, dynamic>> challenges;
  
  const ChallengesLoaded(this.challenges);
  
  @override
  List<Object?> get props => [challenges];
}

class ChallengeCompleted extends AchievementState {
  final Map<String, dynamic> result;
  
  const ChallengeCompleted(this.result);
  
  @override
  List<Object?> get props => [result];
}

class AchievementProgressLoaded extends AchievementState {
  final Map<String, int> progress;
  
  const AchievementProgressLoaded(this.progress);
  
  @override
  List<Object?> get props => [progress];
}

// Error states
class AchievementError extends AchievementState {
  final String message;
  
  const AchievementError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Empty states
class AchievementEmpty extends AchievementState {
  final String message;
  
  const AchievementEmpty({this.message = 'No achievements available'});
  
  @override
  List<Object?> get props => [message];
}

class UserAchievementsEmpty extends AchievementState {
  final String message;
  
  const UserAchievementsEmpty({this.message = 'No achievements unlocked yet'});
  
  @override
  List<Object?> get props => [message];
}
