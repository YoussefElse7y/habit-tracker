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
  String? _currentUserId;
  
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
        if (achievements.isEmpty) {
          emit(const AchievementEmpty(message: 'No achievements available'));
        } else {
          _allAchievements = achievements;
          emit(AllAchievementsLoaded(achievements: achievements));
        }
      },
    );
  }

  /// Load user-specific unlocked achievements
  Future<void> loadUserAchievements(String userId) async {
    if (userId.isEmpty) {
      emit(const AchievementError(message: 'User ID is required'));
      return;
    }
    
    emit(const AchievementLoading());
    final result = await checkAchievements(CheckAchievementsParams(
      userId: userId,
      progressData: {},
    ));
    result.fold(
      (failure) => emit(AchievementError(message: failure.message)),
      (achievements) {
        if (achievements.isEmpty) {
          emit(const UserAchievementsEmpty(message: 'No achievements unlocked yet'));
        } else {
          _unlockedAchievements = achievements;
          emit(UserAchievementsLoaded(achievements: achievements));
        }
      },
    );
  }

  /// Load user stats (points, level, streak, etc.)
  Future<void> loadUserStats(String userId) async {
    if (userId.isEmpty) {
      emit(const AchievementError(message: 'User ID is required'));
      return;
    }
    
    emit(const AchievementLoading());
    final result = await getUserStats(GetUserStatsParams(userId: userId));
    result.fold(
      (failure) => emit(AchievementError(message: failure.message)),
      (stats) {
        _userStats = stats;
        emit(UserStatsLoaded(stats));
      },
    );
  }

  /// Load achievement progress for current user
  Future<void> loadAchievementProgress(String userId) async {
    if (userId.isEmpty) {
      emit(const AchievementError(message: 'User ID is required'));
      return;
    }
    
    if (_allAchievements.isEmpty) {
      await loadAllAchievements();
    }
    emit(const AchievementLoading());
    final result = await getAchievementProgress(GetAchievementProgressParams(
      userId: userId,
      achievements: _allAchievements,
    ));
    result.fold(
      (failure) => emit(AchievementError(message: failure.message)),
      (progressMap) {
        // Convert Map<String, int> to List<AchievementProgress> for internal use
        _achievementProgress = progressMap.entries.map((entry) {
          return AchievementProgress(
            id: entry.key,
            userId: userId,
            achievementId: entry.key,
            currentProgress: entry.value,
            requiredProgress: _getRequiredProgress(entry.key),
            lastUpdated: DateTime.now(),
          );
        }).toList();
        emit(AchievementProgressLoaded(progress: _achievementProgress));
      },
    );
  }

  /// Award points and check for level-up
  Future<void> awardPointsToUser(String userId, int points, String reason) async {
    if (userId.isEmpty) {
      emit(const AchievementError(message: 'User ID is required'));
      return;
    }
    
    emit(const AchievementLoading());
    final result = await awardPoints(AwardPointsParams(
      userId: userId,
      points: points,
      reason: reason,
    ));
    await result.fold(
      (failure) async => emit(AchievementError(message: failure.message)),
      (newTotal) async {
        await loadUserStats(userId);
        await _checkLevelUp();
        emit(PointsAwarded(points: points, newTotal: newTotal, reason: reason));
      },
    );
  }

  /// Check and unlock new achievements
  Future<void> checkAndUnlockAchievements(String userId, Map<String, dynamic> progressData) async {
    if (userId.isEmpty) {
      emit(const AchievementError(message: 'User ID is required'));
      return;
    }
    
    emit(const AchievementLoading());
    final result = await checkAchievements(CheckAchievementsParams(
      userId: userId,
      progressData: progressData,
    ));
    result.fold(
      (failure) => emit(AchievementError(message: failure.message)),
      (newAchievements) async {
        if (newAchievements.isNotEmpty) {
          _unlockedAchievements.addAll(newAchievements);
          emit(AchievementsUnlocked(achievements: newAchievements));
          
          // Refresh user stats and achievements after unlocking achievements
          await loadUserStats(userId);
          await loadUserAchievements(userId);
          await loadAchievementProgress(userId);
        } else {
          // Even if no new achievements, refresh progress
          await loadUserStats(userId);
          await loadUserAchievements(userId);
          await loadAchievementProgress(userId);
        }
      },
    );
  }

  /// Load leaderboard data
  Future<void> loadLeaderboard({String? category, int limit = 10}) async {
    emit(const AchievementLoading());
    final result = await getLeaderboard(GetLeaderboardParams(
      category: category,
      limit: limit,
    ));
    result.fold(
      (failure) => emit(AchievementError(message: failure.message)),
      (leaderboardData) {
        // Convert Map data to LeaderboardEntry objects using your existing entity structure
        _leaderboard = leaderboardData.map((data) {
          return LeaderboardEntry(
            userId: data['userId'] ?? '',
            username: data['username'] ?? 'Unknown',
            displayName: data['displayName'],
            avatarUrl: data['avatarUrl'],
            rank: data['rank'] ?? 0,
            totalPoints: data['totalPoints'] ?? data['points'] ?? 0, // Handle both field names
            currentLevel: data['currentLevel'] ?? data['level'] ?? 1,
            totalCompletions: data['totalCompletions'] ?? 0,
            currentStreak: data['currentStreak'] ?? data['streak'] ?? 0,
            longestStreak: data['longestStreak'] ?? 0,
            unlockedAchievements: data['unlockedAchievements'] ?? 0,
            lastActivity: data['lastActivity'] != null 
                ? DateTime.parse(data['lastActivity'].toString())
                : DateTime.now(),
            category: data['category'],
            additionalStats: Map<String, dynamic>.from(data['additionalStats'] ?? {}),
          );
        }).toList();
        emit(LeaderboardLoaded(leaderboard: _leaderboard));
      },
    );
  }

  /// Recover streak
  Future<void> recoverUserStreak(String userId, String habitId) async {
    if (userId.isEmpty || habitId.isEmpty) {
      emit(const AchievementError(message: 'User ID and Habit ID are required'));
      return;
    }
    
    emit(const AchievementLoading());
    final result = await recoverStreak(RecoverStreakParams(
      userId: userId,
      habitId: habitId,
    ));
    await result.fold(
      (failure) async => emit(AchievementError(message: failure.message)),
      (_) async {
        await loadUserStats(userId);
        emit(const StreakRecovered());
      },
    );
  }

  /// Load challenges
  Future<void> loadChallenges({String? timeFrame, String? category}) async {
    emit(const AchievementLoading());
    final result = await getChallenges(GetChallengesParams(
      timeFrame: timeFrame,
      category: category,
    ));
    result.fold(
      (failure) => emit(AchievementError(message: failure.message)),
      (challengeData) {
        // Convert Map data to Challenge objects
        _challenges = challengeData.map((data) {
          return Challenge(
            id: data['id'] ?? '',
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            type: _parseEnum(data['type'], ChallengeType.values, ChallengeType.daily),
            status: _parseEnum(data['status'], ChallengeStatus.values, ChallengeStatus.active),
            startDate: DateTime.parse(data['startDate'] ?? DateTime.now().toIso8601String()),
            endDate: DateTime.parse(data['endDate'] ?? DateTime.now().add(const Duration(days: 1)).toIso8601String()),
            pointsReward: data['pointsReward'] ?? 0,
            requirements: List<String>.from(data['requirements'] ?? []),
            criteria: Map<String, dynamic>.from(data['criteria'] ?? {}),
          );
        }).toList();
        emit(ChallengesLoaded(challenges: _challenges));
      },
    );
  }

  /// Comprehensive refresh of all data
  Future<void> refreshAllData(String userId) async {
    if (userId.isEmpty) {
      emit(const AchievementError(message: 'User ID is required'));
      return;
    }
    
    _currentUserId = userId;
    emit(const AchievementLoading());
    
    try {
      // Load core data first
      await loadAllAchievements();
      await loadUserStats(userId);
      
      // Then load dependent data
      await Future.wait([
        loadUserAchievements(userId),
        loadAchievementProgress(userId),
        loadLeaderboard(),
        loadChallenges(),
      ]);
      
      // Emit success state when all is loaded
      if (_userStats != null) {
        emit(UserStatsLoaded(_userStats!));
      } else {
        emit(const AchievementError(message: 'Failed to load user stats'));
      }
    } catch (e) {
      emit(AchievementError(message: 'Failed to refresh data: ${e.toString()}'));
    }
  }

  /// Helper methods for accessing cached data
  int get totalAchievements => _allAchievements.length;
  int get unlockedCount => _unlockedAchievements.length;
  double get completionPercentage =>
      totalAchievements == 0 ? 0 : (unlockedCount / totalAchievements) * 100;

  UserStats? get userStats => _userStats;
  List<Achievement> get userAchievements => _unlockedAchievements;
  List<Achievement> get allAchievements => _allAchievements;
  List<AchievementProgress> get progress => _achievementProgress;
  List<LeaderboardEntry> get leaderboardEntries => _leaderboard;
  List<Challenge> get challenges => _challenges;

  /// Get achievement progress as a map for backward compatibility
  Map<String, int> get achievementProgress {
    if (_userStats == null) return {};
    
    return {
      'currentStreak': _userStats!.currentStreak,
      'longestStreak': _userStats!.longestStreak,
      'totalCompletions': _userStats!.totalCompletions,
      'totalHabits': _userStats!.totalHabits,
      'activeHabits': _userStats!.activeHabits,
      'totalPoints': _userStats!.totalPoints,
      'currentLevel': _userStats!.currentLevel,
      'totalAchievements': _userStats!.totalAchievements,
      'unlockedAchievements': _userStats!.unlockedAchievements,
    };
  }

  /// Get next achievements that are close to being unlocked
  List<Achievement> get nextAchievableAchievements {
    final locked = getLockedAchievements();
    if (locked.isEmpty || _userStats == null) return [];
    
    // Sort by how close they are to being unlocked
    locked.sort((a, b) {
      final progressA = _getProgressForAchievement(a);
      final progressB = _getProgressForAchievement(b);
      final remainingA = (a.requirement - progressA).clamp(0, a.requirement);
      final remainingB = (b.requirement - progressB).clamp(0, b.requirement);
      return remainingA.compareTo(remainingB);
    });
    
    return locked.take(5).toList();
  }

  List<Achievement> getAchievementsByType(AchievementType type) =>
      _allAchievements.where((a) => a.type == type).toList();

  List<Achievement> getAchievementsByTier(AchievementTier tier) =>
      _allAchievements.where((a) => a.tier == tier).toList();

  List<Achievement> getLockedAchievements() => _allAchievements
      .where((a) => !_unlockedAchievements.any((ua) => ua.id == a.id))
      .toList();

  Achievement? getNextAchievement() {
    final locked = getLockedAchievements();
    if (locked.isEmpty) return null;
    locked.sort((a, b) => a.points.compareTo(b.points));
    return locked.first;
  }

  /// Reset all cached data
  void resetState() {
    _allAchievements = [];
    _unlockedAchievements = [];
    _achievementProgress = [];
    _userStats = null;
    _leaderboard = [];
    _challenges = [];
    _currentUserId = null;
    emit(const AchievementInitial());
  }

  /// Private helper methods
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
      threshold += AppConstants.pointsPerLevel * level;
    }
    return level;
  }

  int _getRequiredProgress(String achievementId) {
    final achievement = _allAchievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => Achievement(
        id: achievementId,
        title: '',
        description: '',
        iconName: '',
        type: AchievementType.streak,
        tier: AchievementTier.bronze,
        requirement: 1,
        points: 0,
      ),
    );
    return achievement.requirement;
  }

  int _getProgressForAchievement(Achievement achievement) {
    if (_userStats == null) return 0;
    
    switch (achievement.type) {
      case AchievementType.streak:
        // Use the higher of current or longest streak
        return _userStats!.currentStreak > _userStats!.longestStreak 
            ? _userStats!.currentStreak 
            : _userStats!.longestStreak;
      case AchievementType.completion:
        return _userStats!.totalCompletions;
      case AchievementType.milestone:
        return _userStats!.totalHabits;
      case AchievementType.special:
        // For special achievements, return 0 as they have custom logic
        return 0;
    }
  }

  T _parseEnum<T>(dynamic value, List<T> values, T defaultValue) {
    if (value is String) {
      try {
        return values.firstWhere((e) => e.toString().split('.').last == value);
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }
}