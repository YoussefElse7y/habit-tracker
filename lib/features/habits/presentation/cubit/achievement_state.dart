// File: features/habits/presentation/cubit/achievement_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/achievement_progress.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/leaderboard_entry.dart';
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
class AllAchievementsLoaded extends AchievementState {
  final List<Achievement> achievements;
  
  const AllAchievementsLoaded({required this.achievements});
  
  @override
  List<Object?> get props => [achievements];
}

class AchievementLoaded extends AchievementState {
  final List<Achievement> achievements;
  
  const AchievementLoaded(this.achievements);
  
  @override
  List<Object?> get props => [achievements];
}

class UserAchievementsLoaded extends AchievementState {
  final List<Achievement> achievements;
  
  const UserAchievementsLoaded({required this.achievements});
  
  @override
  List<Object?> get props => [achievements];
}

class UserStatsLoaded extends AchievementState {
  final UserStats stats;
  
  const UserStatsLoaded(this.stats);
  
  @override
  List<Object?> get props => [stats];
}

class AchievementProgressLoaded extends AchievementState {
  final List<AchievementProgress> progress;
  
  const AchievementProgressLoaded({required this.progress});
  
  @override
  List<Object?> get props => [progress];
}

class AchievementsUnlocked extends AchievementState {
  final List<Achievement> achievements;
  
  const AchievementsUnlocked({required this.achievements});
  
  @override
  List<Object?> get props => [achievements];
}

class AchievementCheckComplete extends AchievementState {
  const AchievementCheckComplete();
}

class PointsAwarded extends AchievementState {
  final int points;
  final String? reason;
  final int? newTotal;
  
  const PointsAwarded({required this.points, this.reason, this.newTotal});
  
  @override
  List<Object?> get props => [points, reason, newTotal];
}

class LevelUpAchieved extends AchievementState {
  final int newLevel;
  final int? previousLevel;
  
  const LevelUpAchieved({required this.newLevel, this.previousLevel});
  
  @override
  List<Object?> get props => [newLevel, previousLevel];
}

class LeaderboardLoaded extends AchievementState {
  final List<LeaderboardEntry> leaderboard;
  
  const LeaderboardLoaded({required this.leaderboard});
  
  @override
  List<Object?> get props => [leaderboard];
}

class StreakRecovered extends AchievementState {
  const StreakRecovered();
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
  final List<Challenge> challenges;
  
  const ChallengesLoaded({required this.challenges});
  
  @override
  List<Object?> get props => [challenges];
}

class ChallengeCompleted extends AchievementState {
  final Map<String, dynamic> result;
  
  const ChallengeCompleted(this.result);
  
  @override
  List<Object?> get props => [result];
}

// Error states
class AchievementError extends AchievementState {
  final String message;
  
  const AchievementError({required this.message});
  
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