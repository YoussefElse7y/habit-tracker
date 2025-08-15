// File: features/habits/presentation/cubit/achievement_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/base_cubit.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../../domain/usecases/check_achievements.dart';
import '../../domain/usecases/get_user_stats.dart';
import 'achievement_state.dart';

class AchievementCubit extends BaseCubit<AchievementState> {
  final AchievementRepository _achievementRepository;
  final CheckAchievements _checkAchievements;
  final GetUserStats _getUserStats;

  AchievementCubit({
    required AchievementRepository achievementRepository,
    required CheckAchievements checkAchievements,
    required GetUserStats getUserStats,
  })  : _achievementRepository = achievementRepository,
        _checkAchievements = checkAchievements,
        _getUserStats = getUserStats,
        super(const AchievementInitial());

  // Cache for achievements and stats
  List<Achievement> _allAchievements = [];
  List<Achievement> _userAchievements = [];
  UserStats? _userStats;
  Map<String, int> _achievementProgress = {};

  // Getters for cached data
  List<Achievement> get allAchievements => List.unmodifiable(_allAchievements);
  List<Achievement> get userAchievements => List.unmodifiable(_userAchievements);
  UserStats? get userStats => _userStats;
  Map<String, int> get achievementProgress => Map.unmodifiable(_achievementProgress);

  /// Load all available achievements
  Future<void> loadAllAchievements() async {
    emit(const AchievementLoading());

    final result = await _achievementRepository.getAllAchievements();

    result.fold(
      (failure) => emit(AchievementError(failure.message)),
      (achievements) {
        _allAchievements = achievements;
        emit(AchievementLoaded(achievements));
      },
    );
  }

  /// Load user's unlocked achievements
  Future<void> loadUserAchievements(String userId) async {
    emit(const AchievementLoading());

    final result = await _achievementRepository.getUserAchievements(userId);

    result.fold(
      (failure) => emit(AchievementError(failure.message)),
      (achievements) {
        _userAchievements = achievements;
        emit(UserAchievementsLoaded(achievements));
      },
    );
  }

  /// Load user statistics and progress
  Future<void> loadUserStats(String userId) async {
    emit(const AchievementLoading());

    final result = await _getUserStats(GetUserStatsParams(userId: userId));

    result.fold(
      (failure) => emit(AchievementError(failure.message)),
      (stats) {
        _userStats = stats;
        emit(UserStatsLoaded(stats));
      },
    );
  }

  /// Check and unlock new achievements based on user progress
  Future<void> checkAchievements(
    String userId,
    Map<String, dynamic> progressData,
  ) async {
    emit(const AchievementChecking());

    final result = await _checkAchievements(CheckAchievementsParams(
      userId: userId,
      progressData: progressData,
    ));

    result.fold(
      (failure) => emit(AchievementError(failure.message)),
      (newAchievements) {
        if (newAchievements.isNotEmpty) {
          // Add new achievements to user's list
          _userAchievements.addAll(newAchievements);
          
          // Update user stats
          if (_userStats != null) {
            final newTotal = _userStats!.unlockedAchievements + newAchievements.length;
            _userStats = _userStats!.copyWith(
              unlockedAchievements: newTotal,
              lastActivity: DateTime.now(),
            );
          }

          emit(AchievementsUnlocked(newAchievements));
          
          // Show unlocked achievements briefly, then return to loaded state
          Future.delayed(const Duration(seconds: 3), () {
            if (!isClosed) {
              emit(UserAchievementsLoaded(_userAchievements));
            }
          });
        } else {
          // No new achievements
          emit(const AchievementCheckComplete());
        }
      },
    );
  }

  /// Award points to user
  Future<void> awardPoints(String userId, int points, String reason) async {
    emit(const AchievementLoading());

    final result = await _achievementRepository.awardPoints(userId, points, reason);

    result.fold(
      (failure) => emit(AchievementError(failure.message)),
      (newTotal) {
        // Update local stats
        if (_userStats != null) {
          _userStats = _userStats!.copyWith(
            totalPoints: newTotal,
            lastActivity: DateTime.now(),
          );
        }

        emit(PointsAwarded(points, reason, newTotal));
        
        // Check if user leveled up
        _checkLevelUp();
      },
    );
  }

  /// Get leaderboard data
  Future<void> loadLeaderboard({String? category, int limit = 10}) async {
    emit(const AchievementLoading());

    final result = await _achievementRepository.getLeaderboard(
      category: category,
      limit: limit,
    );

    result.fold(
      (failure) => emit(AchievementError(failure.message)),
      (leaderboard) => emit(LeaderboardLoaded(leaderboard)),
    );
  }

  /// Get streak recovery options
  Future<void> loadStreakRecoveryOptions(String userId) async {
    emit(const AchievementLoading());

    final result = await _achievementRepository.getStreakRecoveryOptions(userId);

    result.fold(
      (failure) => emit(AchievementError(failure.message)),
      (options) => emit(StreakRecoveryOptionsLoaded(options)),
    );
  }

  /// Use streak recovery
  Future<void> useStreakRecovery(String userId, String habitId) async {
    emit(const AchievementLoading());

    final result = await _achievementRepository.useStreakRecovery(userId, habitId);

    result.fold(
      (failure) => emit(AchievementError(failure.message)),
      (success) {
        if (success) {
          emit(const StreakRecoveryUsed());
        } else {
          emit(const AchievementError('Failed to use streak recovery'));
        }
      },
    );
  }

  /// Get challenges
  Future<void> loadChallenges({String? timeFrame, String? category}) async {
    emit(const AchievementLoading());

    final result = await _achievementRepository.getChallenges(
      timeFrame: timeFrame,
      category: category,
    );

    result.fold(
      (failure) => emit(AchievementError(failure.message)),
      (challenges) => emit(ChallengesLoaded(challenges)),
    );
  }

  /// Complete a challenge
  Future<void> completeChallenge(String userId, String challengeId) async {
    emit(const AchievementLoading());

    final result = await _achievementRepository.completeChallenge(userId, challengeId);

    result.fold(
      (failure) => emit(AchievementError(failure.message)),
      (challengeResult) => emit(ChallengeCompleted(challengeResult)),
    );
  }

  /// Get achievement progress for display
  Future<void> loadAchievementProgress(String userId) async {
    if (_allAchievements.isEmpty) {
      await loadAllAchievements();
    }

    final result = await _achievementRepository.getAchievementProgress(
      userId,
      _allAchievements,
    );

    result.fold(
      (failure) => emit(AchievementError(failure.message)),
      (progress) {
        _achievementProgress = progress;
        emit(AchievementProgressLoaded(progress));
      },
    );
  }

  /// Check if user leveled up
  void _checkLevelUp() {
    if (_userStats != null) {
      final currentLevel = _userStats!.currentLevel;
      final newLevel = _calculateLevel(_userStats!.totalPoints);
      
      if (newLevel > currentLevel) {
        _userStats = _userStats!.copyWith(currentLevel: newLevel);
        emit(LevelUpAchieved(currentLevel, newLevel));
        
        // Show level up briefly, then return to stats loaded state
        Future.delayed(const Duration(seconds: 3), () {
          if (!isClosed) {
            emit(UserStatsLoaded(_userStats!));
          }
        });
      }
    }
  }

  /// Calculate level based on total points
  int _calculateLevel(int totalPoints) {
    int level = 1;
    int pointsNeeded = 0;
    
    while (totalPoints >= pointsNeeded) {
      level++;
      pointsNeeded = 100 * (level - 1) * (level - 1);
    }
    
    return level - 1;
  }

  /// Refresh all achievement data
  Future<void> refreshAllData(String userId) async {
    await Future.wait([
      loadAllAchievements(),
      loadUserAchievements(userId),
      loadUserStats(userId),
      loadAchievementProgress(userId),
    ]);
  }

  /// Clear cache and reset to initial state
  void resetState() {
    _allAchievements.clear();
    _userAchievements.clear();
    _userStats = null;
    _achievementProgress.clear();
    emit(const AchievementInitial());
  }

  /// Get achievement by ID
  Achievement? getAchievementById(String id) {
    try {
      return _allAchievements.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get unlocked achievements count
  int get unlockedAchievementsCount => _userAchievements.length;

  /// Get total achievements count
  int get totalAchievementsCount => _allAchievements.length;

  /// Get achievement completion percentage
  double get achievementCompletionPercentage {
    if (_allAchievements.isEmpty) return 0.0;
    return (_userAchievements.length / _allAchievements.length) * 100;
  }

  /// Get achievements by type
  List<Achievement> getAchievementsByType(AchievementType type) {
    return _allAchievements.where((achievement) => achievement.type == type).toList();
  }

  /// Get achievements by tier
  List<Achievement> getAchievementsByTier(AchievementTier tier) {
    return _allAchievements.where((achievement) => achievement.achievementTier == tier).toList();
  }

  /// Get locked achievements
  List<Achievement> get lockedAchievements {
    return _allAchievements.where((achievement) => !achievement.isUnlocked).toList();
  }

  /// Get next achievable achievements (sorted by requirement)
  List<Achievement> get nextAchievableAchievements {
    final locked = lockedAchievements;
    locked.sort((a, b) => a.requirement.compareTo(b.requirement));
    return locked.take(5).toList(); // Return top 5 next achievable
  }
}