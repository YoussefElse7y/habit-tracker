// File: features/habits/presentation/cubit/achievement_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:habit_tracker_app/core/usecases/usecase.dart';
import 'package:habit_tracker_app/features/habits/presentation/cubit/achievement_state.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/entities/achievement_progress.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/usecases/award_points.dart';
import '../../domain/usecases/check_achievements.dart';
import '../../domain/usecases/get_all_achievements.dart';
import '../../domain/usecases/get_achievement_progress.dart';
import '../../domain/usecases/get_challenges.dart';
import '../../domain/usecases/get_leaderboard.dart';
import '../../domain/usecases/recover_streak.dart';
import '../../domain/usecases/get_user_stats.dart';

class AchievementCubit extends Cubit<AchievementState> {
  final GetUserStats getUserStats;
  final GetAllAchievements getAllAchievements;
  final CheckAchievements checkAchievements;
  final GetAchievementProgress getAchievementProgress;
  final AwardPoints awardPoints;
  final GetLeaderboard getLeaderboard;
  final RecoverStreak recoverStreak;
  final GetChallenges getChallenges;
  
  List<AchievementProgress> _achievementProgress = [];
  List<LeaderboardEntry> _leaderboard = [];
  List<Challenge> _challenges = [];
  List<Achievement> _allAchievements = [];
  List<Achievement> _unlockedAchievements = [];
  UserStats? _userStats;
  
  AchievementCubit({
    required this.getAllAchievements,
    required this.getUserStats,
    required this.checkAchievements,
    required this.getAchievementProgress,
    required this.awardPoints,
    required this.getLeaderboard,
    required this.recoverStreak,
    required this.getChallenges,
  }) : super(const AchievementInitial());

  /// Load all achievements from repository
  Future<void> loadAllAchievements() async {
    emit(const AchievementLoading());
    final result = await getAllAchievements(NoParams());
    result.fold(
      (failure) => emit(AchievementError(message: failure.message)),
      (achievements) {
        _allAchievements = achievements;
        emit(AllAchievementsLoaded(achievements: achievements));
      },
    );
  }

  /// Load user-specific unlocked achievements
  Future<void> loadUserAchievements() async {
    emit(const AchievementLoading());
    final result = await checkAchievements.getUnlockedAchievements();
    result.fold(
      (failure) => emit(AchievementError(message: failure.message)),
      (achievements) {
        _unlockedAchievements = achievements;
        emit(UserAchievementsLoaded(achievements: achievements));
      },
    );
  }

  /// Load user stats (points, level, streak, etc.)
  Future<void> loadUserStats() async {
    emit(const AchievementLoading());
    final result = await getUserStats(NoParams());
    result.fold(
      (failure) => emit(AchievementError(message: failure.message)),
      (stats) {
        _userStats = stats;
        emit(UserStatsLoaded(stats));
      },
    );
  }

  /// Load achievement progress for current user
  Future<void> loadAchievementProgress() async {
    if (_allAchievements.isEmpty) {
      await loadAllAchievements();
    }
    emit(const AchievementLoading());
    final result = await getAchievementProgress(NoParams());
    result.fold(
      (failure) => emit(AchievementError(message: failure.message)),
      (progress) {
        _achievementProgress = progress;
        emit(AchievementProgressLoaded(progress: progress));
      },
    );
  }

  /// Award points and check for level-up
  Future<void> awardPointsToUser(int points) async {
    emit(const AchievementLoading());
    final result = await awardPoints(AwardPointsParams(points: points));
    await result.fold(
      (failure) async => emit(AchievementError(message: failure.message)),
      (_) async {
        await loadUserStats();
        await _checkLevelUp();
        emit(PointsAwarded(points: points));
      },
    );
  }

  /// Check and unlock new achievements
  Future<void> checkAndUnlockAchievements() async {
    emit(const AchievementLoading());
    final result = await checkAchievements(NoParams());
    result.fold(
      (failure) => emit(AchievementError(message: failure.message)),
      (newAchievements) {
        _unlockedAchievements.addAll(newAchievements);
        emit(AchievementsUnlocked(achievements: newAchievements));
      },
    );
  }

  /// Load leaderboard data
  Future<void> loadLeaderboard() async {
    emit(const AchievementLoading());
    final result = await getLeaderboard(NoParams());
    result.fold(
      (failure) => emit(AchievementError(message: failure.message)),
      (leaderboard) {
        _leaderboard = leaderboard;
        emit(LeaderboardLoaded(leaderboard: leaderboard));
      },
    );
  }

  /// Recover streak
  Future<void> recoverUserStreak() async {
    emit(const AchievementLoading());
    final result = await recoverStreak(NoParams());
    await result.fold(
      (failure) async => emit(AchievementError(message: failure.message)),
      (_) async {
        await loadUserStats();
        emit(const StreakRecovered());
      },
    );
  }

  /// Load challenges
  Future<void> loadChallenges() async {
    emit(const AchievementLoading());
    final result = await getChallenges(NoParams());
    result.fold(
      (failure) => emit(AchievementError(message: failure.message)),
      (challenges) {
        _challenges = challenges;
        emit(ChallengesLoaded(challenges: challenges));
      },
    );
  }

  /// Helpers
  int get totalAchievements => _allAchievements.length;
  int get unlockedCount => _unlockedAchievements.length;
  double get completionPercentage =>
      totalAchievements == 0 ? 0 : (unlockedCount / totalAchievements) * 100;

  List<Achievement> getAchievementsByType(AchievementType type) =>
      _allAchievements.where((a) => a.type == type).toList();

  List<Achievement> getAchievementsByTier(AchievementTier tier) =>
      _allAchievements.where((a) => a.tier == tier).toList();

  List<Achievement> getLockedAchievements() => _allAchievements
      .where((a) => !_unlockedAchievements.contains(a))
      .toList();

  Achievement? getNextAchievement() {
    final locked = getLockedAchievements();
    if (locked.isEmpty) return null;
    locked.sort((a, b) => a.points.compareTo(b.points));
    return locked.first;
  }

  List<AchievementProgress> getProgress() => _achievementProgress;
  UserStats? getUserStatsCached() => _userStats;
  List<LeaderboardEntry> getLeaderboardCached() => _leaderboard;
  List<Challenge> getChallengesCached() => _challenges;

  /// Reset all cached data
  void resetState() {
    _allAchievements = [];
    _unlockedAchievements = [];
    _achievementProgress = [];
    _userStats = null;
    _leaderboard = [];
    _challenges = [];
    emit(const AchievementInitial());
  }

  Future<void> _checkLevelUp() async {
    if (_userStats == null) return;
    final currentLevel = _userStats!.currentLevel;
    final newLevel = _calculateLevel(_userStats!.totalPoints);
    if (newLevel > currentLevel) {
      emit(LevelUpAchieved(newLevel: newLevel, previousLevel: currentLevel));
    }
  }

  int _calculateLevel(int points) {
    int level = 1;
    int threshold = AppConstants.pointsPerLevel;
    while (points >= threshold) {
      level++;
      threshold += AppConstants.pointsPerLevel;
    }
    return level;
  }
}