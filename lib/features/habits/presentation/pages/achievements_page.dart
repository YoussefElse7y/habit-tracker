// File: features/habits/presentation/pages/achievements_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/achievement.dart';
import '../cubit/achievement_cubit.dart';
import '../cubit/achievement_state.dart' as states;
import '../widgets/achievement_card.dart';
import '../widgets/user_stats_card.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({Key? key}) : super(key: key);

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (_currentUserId != null) {
      context.read<AchievementCubit>().refreshAllData(_currentUserId!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Achievements & Stats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Streaks'),
            Tab(text: 'Milestones'),
            Tab(text: 'Special'),
          ],
        ),
      ),
      body: BlocConsumer<AchievementCubit, states.AchievementState>(
        listener: (context, state) {
          if (state is states.AchievementsUnlocked) {
            _showAchievementUnlockedDialog(state.achievements);
          } else if (state is states.LevelUpAchieved) {
            _showLevelUpDialog(state.newLevel);
          } else if (state is states.PointsAwarded) {
            _showPointsAwardedSnackBar(state.points);
          } else if (state is states.AchievementError) {
            _showErrorSnackBar(state.message);
          }
        },
        builder: (context, state) {
          if (state is states.AchievementLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading achievements...'),
                ],
              ),
            );
          }

          if (state is states.AchievementError) {
            return _buildErrorView(state.message);
          }

          if (state is states.AchievementEmpty) {
            return _buildEmptyView(state.message);
          }

          if (state is states.UserAchievementsEmpty) {
            return _buildEmptyView(state.message);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildStreaksTab(),
              _buildMilestonesTab(),
              _buildSpecialTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading achievements',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_currentUserId != null) {
                  context.read<AchievementCubit>().refreshAllData(_currentUserId!);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final cubit = context.read<AchievementCubit>();
    final userStats = cubit.userStats;
    final totalAchievements = cubit.totalAchievements;
    final unlockedCount = cubit.unlockedCount;
    final completionPercentage = cubit.completionPercentage;

    // Check if we have the necessary data
    if (userStats == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading user stats...'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_currentUserId != null) {
          await cubit.refreshAllData(_currentUserId!);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Stats Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level ${userStats.currentLevel}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${userStats.totalPoints} points',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildStatItem('Streak', '${userStats.currentStreak}'),
                      _buildStatItem('Total', '${userStats.totalCompletions}'),
                      _buildStatItem('Achievements', '$unlockedCount/$totalAchievements'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Achievement Progress Overview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Achievement Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${completionPercentage.toInt()}% Complete',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: completionPercentage / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$unlockedCount/$totalAchievements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent Achievements
            if (cubit.userAchievements.isNotEmpty) ...[
              const Text(
                'Recent Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...cubit.userAchievements
                  .take(3)
                  .map((achievement) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AchievementCard(
                          achievement: achievement,
                          isUnlocked: true,
                          onTap: () => _showAchievementDetails(achievement),
                        ),
                      ))
                  .toList(),
              const SizedBox(height: 24),
            ],

            // Next Achievements
            if (cubit.nextAchievableAchievements.isNotEmpty) ...[
              const Text(
                'Next to Unlock',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...cubit.nextAchievableAchievements
                  .take(3)
                  .map((achievement) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AchievementCard(
                          achievement: achievement,
                          isUnlocked: false,
                          showProgress: true,
                          currentProgress: _getAchievementProgress(achievement),
                          onTap: () => _showAchievementDetails(achievement),
                        ),
                      ))
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreaksTab() {
    final cubit = context.read<AchievementCubit>();
    final streakAchievements = cubit.getAchievementsByType(AchievementType.streak);

    return RefreshIndicator(
      onRefresh: () async {
        if (_currentUserId != null) {
          await cubit.refreshAllData(_currentUserId!);
        }
      },
      child: _buildAchievementsList(streakAchievements, 'No streak achievements available'),
    );
  }

  Widget _buildMilestonesTab() {
    final cubit = context.read<AchievementCubit>();
    final milestoneAchievements = cubit.getAchievementsByType(AchievementType.milestone);

    return RefreshIndicator(
      onRefresh: () async {
        if (_currentUserId != null) {
          await cubit.refreshAllData(_currentUserId!);
        }
      },
      child: _buildAchievementsList(milestoneAchievements, 'No milestone achievements available'),
    );
  }

  Widget _buildSpecialTab() {
    final cubit = context.read<AchievementCubit>();
    final specialAchievements = cubit.getAchievementsByType(AchievementType.special);

    return RefreshIndicator(
      onRefresh: () async {
        if (_currentUserId != null) {
          await cubit.refreshAllData(_currentUserId!);
        }
      },
      child: _buildAchievementsList(specialAchievements, 'No special achievements available'),
    );
  }

  Widget _buildAchievementsList(List<Achievement> achievements, String emptyMessage) {
    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final isUnlocked = context.read<AchievementCubit>().userAchievements
            .any((ua) => ua.id == achievement.id);
        final currentProgress = _getAchievementProgress(achievement);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AchievementCard(
            achievement: achievement,
            isUnlocked: isUnlocked,
            showProgress: !isUnlocked,
            currentProgress: currentProgress,
            onTap: () => _showAchievementDetails(achievement),
          ),
        );
      },
    );
  }

  Color _getTierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
      case AchievementTier.diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  int _getAchievementProgress(Achievement achievement) {
    final cubit = context.read<AchievementCubit>();
    final progressMap = cubit.achievementProgress;

    switch (achievement.type) {
      case AchievementType.streak:
        return progressMap['currentStreak'] ?? 0;
      case AchievementType.completion:
        return progressMap['totalCompletions'] ?? 0;
      case AchievementType.milestone:
        return progressMap['totalHabits'] ?? 0;
      case AchievementType.special:
        return 0;
    }
  }

  void _showAchievementUnlockedDialog(List<Achievement> achievements) {
    if (achievements.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Achievement Unlocked!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: achievements.map((achievement) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getTierColor(achievement.tier).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: _getTierColor(achievement.tier),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${achievement.points} points earned!',
                        style: TextStyle(
                          color: _getTierColor(achievement.tier),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text('Awesome!', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelUpDialog(int newLevel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.trending_up, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Level Up!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LEVEL $newLevel',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Congratulations! 🎉',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep up the great work and continue building your habits!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPointsAwardedSnackBar(int points) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Text('+$points points earned!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    final isUnlocked = context.read<AchievementCubit>().userAchievements
        .any((ua) => ua.id == achievement.id);
    final currentProgress = _getAchievementProgress(achievement);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: isUnlocked ? _getTierColor(achievement.tier) : Colors.grey,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                achievement.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Progress bar for locked achievements
            if (!isUnlocked && achievement.requirement > 0) ...[
              Text(
                'Progress: $currentProgress / ${achievement.requirement}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: achievement.requirement > 0
                    ? (currentProgress / achievement.requirement).clamp(0.0, 1.0)
                    : 0.0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_getTierColor(achievement.tier)),
              ),
              const SizedBox(height: 16),
            ],

            // Status and details
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUnlocked 
                        ? _getTierColor(achievement.tier) 
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    achievement.tier.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${achievement.points} points',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'UNLOCKED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}