// File: features/habits/presentation/pages/achievements_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habit_tracker_app/features/habits/domain/entities/achievement.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/achievement_constants.dart';
import '../cubit/achievement_cubit.dart';
import '../cubit/achievement_state.dart';
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
      body: BlocConsumer<AchievementCubit, AchievementState>(
        listener: (context, state) {
          if (state is AchievementsUnlocked) {
            _showAchievementUnlockedDialog(state.newAchievements);
          } else if (state is LevelUpAchieved) {
            _showLevelUpDialog(state.previousLevel, state.newLevel);
          } else if (state is PointsAwarded) {
            _showPointsAwardedSnackBar(state.points, state.reason);
          }
        },
        builder: (context, state) {
          if (state is AchievementLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AchievementError) {
            return Center(
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
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentUserId != null) {
                        context.read<AchievementCubit>().refreshAllData(_currentUserId!);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(state),
              _buildStreaksTab(state),
              _buildMilestonesTab(state),
              _buildSpecialTab(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(AchievementState state) {
    return RefreshIndicator(
      onRefresh: () async {
        if (_currentUserId != null) {
          await context.read<AchievementCubit>().refreshAllData(_currentUserId!);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (state is UserStatsLoaded)
              UserStatsCard(
                stats: state.stats,
                onTap: () {},
              ),
            Container(
              margin: const EdgeInsets.all(16),
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
                  ...AchievementTier.values.map((tier) {
                    final tierAchievements = AchievementConstants.getAchievementsByTier(tier);
                    final unlockedCount = tierAchievements.where((a) => 
                      context.read<AchievementCubit>().userAchievements
                          .any((ua) => ua.id == a.id)
                    ).length;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tier.name.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _getTierColor(tier),
                                ),
                              ),
                              Text(
                                '$unlockedCount/${tierAchievements.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: tierAchievements.isEmpty ? 0 : unlockedCount / tierAchievements.length,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(_getTierColor(tier)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            if (state is UserAchievementsLoaded && state.achievements.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Achievements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...state.achievements
                        .take(3)
                        .map((achievement) => AchievementCard(
                              achievement: achievement,
                              isUnlocked: true,
                              onTap: () => _showAchievementDetails(achievement),
                            ))
                        .toList(),
                  ],
                ),
              ),
            Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next to Unlock',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...context.read<AchievementCubit>().nextAchievableAchievements
                      .take(3)
                      .map((achievement) => AchievementCard(
                            achievement: achievement,
                            isUnlocked: false,
                            showProgress: true,
                            currentProgress: _getAchievementProgress(achievement),
                            onTap: () => _showAchievementDetails(achievement),
                          ))
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreaksTab(AchievementState state) {
    final streakAchievements = AchievementConstants.streakAchievements;
    
    return RefreshIndicator(
      onRefresh: () async {
        if (_currentUserId != null) {
          await context.read<AchievementCubit>().refreshAllData(_currentUserId!);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: streakAchievements.length,
        itemBuilder: (context, index) {
          final achievement = streakAchievements[index];
          final isUnlocked = context.read<AchievementCubit>().userAchievements
              .any((ua) => ua.id == achievement.id);
          final currentProgress = _getAchievementProgress(achievement);
          
          return AchievementCard(
            achievement: achievement,
            isUnlocked: isUnlocked,
            showProgress: !isUnlocked,
            currentProgress: currentProgress,
            onTap: () => _showAchievementDetails(achievement),
          );
        },
      ),
    );
  }

  Widget _buildMilestonesTab(AchievementState state) {
    final milestoneAchievements = [
      ...AchievementConstants.milestoneAchievements,
      ...AchievementConstants.completionAchievements,
    ];
    
    return RefreshIndicator(
      onRefresh: () async {
        if (_currentUserId != null) {
          await context.read<AchievementCubit>().refreshAllData(_currentUserId!);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: milestoneAchievements.length,
        itemBuilder: (context, index) {
          final achievement = milestoneAchievements[index];
          final isUnlocked = context.read<AchievementCubit>().userAchievements
              .any((ua) => ua.id == achievement.id);
          final currentProgress = _getAchievementProgress(achievement);
          
          return AchievementCard(
            achievement: achievement,
            isUnlocked: isUnlocked,
            showProgress: !isUnlocked,
            currentProgress: currentProgress,
            onTap: () => _showAchievementDetails(achievement),
          );
        },
      ),
    );
  }

  Widget _buildSpecialTab(AchievementState state) {
    final specialAchievements = [
      ...AchievementConstants.specialAchievements,
      ...AchievementConstants.categoryAchievements,
    ];
    
    return RefreshIndicator(
      onRefresh: () async {
        if (_currentUserId != null) {
          await context.read<AchievementCubit>().refreshAllData(_currentUserId!);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: specialAchievements.length,
        itemBuilder: (context, index) {
          final achievement = specialAchievements[index];
          final isUnlocked = context.read<AchievementCubit>().userAchievements
              .any((ua) => ua.id == achievement.id);
          final currentProgress = _getAchievementProgress(achievement);
          
          return AchievementCard(
            achievement: achievement,
            isUnlocked: isUnlocked,
            showProgress: !isUnlocked,
            currentProgress: currentProgress,
            onTap: () => _showAchievementDetails(achievement),
          );
        },
      ),
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
    final progress = cubit.achievementProgress;
    
    switch (achievement.type) {
      case AchievementType.streak:
        return progress['currentStreak'] ?? 0;
      case AchievementType.completion:
        return progress['totalCompletions'] ?? 0;
      case AchievementType.milestone:
        return progress['totalHabits'] ?? 0;
      case AchievementType.special:
        return 0;
    }
  }

  void _showAchievementUnlockedDialog(List<Achievement> achievements) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Achievement Unlocked!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: achievements.map((achievement) => ListTile(
            leading: Icon(
              Icons.emoji_events,
              color: _getTierColor(achievement.tier),
            ),
            title: Text(achievement.title),
            subtitle: Text('${achievement.points} points earned!'),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  void _showLevelUpDialog(int previousLevel, int newLevel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.trending_up, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Level Up!'),
          ],
        ),
        content: Text(
          'Congratulations! You\'ve reached Level $newLevel! 🎉\n\n'
          'Keep up the great work and continue building your habits!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showPointsAwardedSnackBar(int points, String reason) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Text('+$points points for $reason!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: _getTierColor(achievement.tier),
            ),
            const SizedBox(width: 8),
            Text(achievement.title),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTierColor(achievement.tier),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
