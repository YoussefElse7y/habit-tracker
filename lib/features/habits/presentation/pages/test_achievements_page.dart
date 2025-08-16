// File: features/habits/presentation/pages/test_achievements_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/achievement_cubit.dart';
import '../cubit/achievement_state.dart';
import '../../domain/entities/achievement.dart';

class TestAchievementsPage extends StatefulWidget {
  const TestAchievementsPage({super.key});

  @override
  State<TestAchievementsPage> createState() => _TestAchievementsPageState();
}

class _TestAchievementsPageState extends State<TestAchievementsPage> {
  @override
  void initState() {
    super.initState();
    // Load achievements and user stats when page loads
    context.read<AchievementCubit>().loadAllAchievements();
    
    // Get current user ID from Firebase Auth
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      context.read<AchievementCubit>().loadUserStats(currentUser.uid);
      context.read<AchievementCubit>().loadUserAchievements(currentUser.uid);
      context.read<AchievementCubit>().loadAchievementProgress(currentUser.uid);
    } else {
      // Use test user ID if no authenticated user
      context.read<AchievementCubit>().loadUserStats('test_user_id');
      context.read<AchievementCubit>().loadUserAchievements('test_user_id');
      context.read<AchievementCubit>().loadAchievementProgress('test_user_id');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Achievements'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocConsumer<AchievementCubit, AchievementState>(
        listener: (context, state) {
          if (state is AchievementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AchievementLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Stats Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User Stats',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (state is UserStatsLoaded) ...[
                          _buildStatRow('Total Points', state.stats.totalPoints.toString()),
                          _buildStatRow('Current Level', state.stats.currentLevel.toString()),
                          _buildStatRow('Total Habits', state.stats.totalHabits.toString()),
                          _buildStatRow('Active Habits', state.stats.activeHabits.toString()),
                          _buildStatRow('Total Completions', state.stats.totalCompletions.toString()),
                          _buildStatRow('Current Streak', state.stats.currentStreak.toString()),
                          _buildStatRow('Longest Streak', state.stats.longestStreak.toString()),
                          _buildStatRow('Total Achievements', state.stats.totalAchievements.toString()),
                          _buildStatRow('Unlocked Achievements', state.stats.unlockedAchievements.toString()),
                        ] else ...[
                          const Text('User stats not loaded'),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Achievement Progress Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Achievement Progress',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (state is UserStatsLoaded) ...[
                          _buildStatRow('Total Achievements Available', '${context.read<AchievementCubit>().totalAchievements}'),
                          _buildStatRow('Unlocked Achievements', '${context.read<AchievementCubit>().unlockedCount}'),
                          _buildStatRow('Completion Percentage', '${context.read<AchievementCubit>().completionPercentage.toStringAsFixed(1)}%'),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'Progress Data:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          ...context.read<AchievementCubit>().achievementProgress.entries.map((entry) => 
                            _buildStatRow(entry.key, entry.value.toString())
                          ),
                        ] else ...[
                          const Text('Achievement progress not loaded'),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // All Achievements Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Achievements',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (state is AllAchievementsLoaded) ...[
                          Text('Total Achievements: ${state.achievements.length}'),
                          const SizedBox(height: 8),
                          ...state.achievements.map((achievement) => _buildAchievementTile(achievement)),
                        ] else ...[
                          const Text('Achievements not loaded'),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Next Achievable Achievements Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Achievable Achievements',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (context.read<AchievementCubit>().nextAchievableAchievements.isNotEmpty) ...[
                          ...context.read<AchievementCubit>().nextAchievableAchievements.take(5).map((achievement) {
                            final progress = context.read<AchievementCubit>().achievementProgress;
                            int currentProgress = 0;
                            
                            switch (achievement.type) {
                              case AchievementType.streak:
                                currentProgress = progress['currentStreak'] ?? 0;
                                break;
                              case AchievementType.completion:
                                currentProgress = progress['totalCompletions'] ?? 0;
                                break;
                              case AchievementType.milestone:
                                currentProgress = progress['totalHabits'] ?? 0;
                                break;
                              case AchievementType.special:
                                currentProgress = 0;
                                break;
                            }
                            
                            return ListTile(
                              leading: Icon(
                                Icons.star_border,
                                color: Colors.grey,
                              ),
                              title: Text(achievement.title),
                              subtitle: Text('${achievement.description}\nProgress: $currentProgress/${achievement.requirement}'),
                              trailing: Text(
                                '${achievement.points} pts',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          }),
                        ] else ...[
                          const Text('No next achievements available'),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Test Buttons
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Reload user stats and achievements for the current user
                            final currentUser = FirebaseAuth.instance.currentUser;
                            if (currentUser != null) {
                              context.read<AchievementCubit>().loadUserStats(currentUser.uid);
                              context.read<AchievementCubit>().loadUserAchievements(currentUser.uid);
                              context.read<AchievementCubit>().loadAchievementProgress(currentUser.uid);
                            } else {
                              context.read<AchievementCubit>().loadUserStats('test_user_id');
                              context.read<AchievementCubit>().loadUserAchievements('test_user_id');
                              context.read<AchievementCubit>().loadAchievementProgress('test_user_id');
                            }
                          },
                          child: const Text('Reload User Stats & Achievements'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            context.read<AchievementCubit>().loadAllAchievements();
                          },
                          child: const Text('Reload Achievements'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Manually update user stats to test
                            final currentUser = FirebaseAuth.instance.currentUser;
                            final userId = currentUser?.uid ?? 'test_user_id';
                            
                            print('Manually updating user stats for: $userId');
                            // This would need to be implemented in the achievement cubit
                            // For now, just show a message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Manual stats update not implemented yet. Check console logs for debugging info.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          child: const Text('Manual Update User Stats'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Test the First Step achievement specifically
                            final currentUser = FirebaseAuth.instance.currentUser;
                            final userId = currentUser?.uid ?? 'test_user_id';
                            
                            print('Testing First Step achievement for user: $userId');
                            context.read<AchievementCubit>().checkAndUnlockAchievements(
                              userId,
                              {
                                'totalHabits': 1,
                                'totalCompletions': 0,
                                'currentStreak': 0,
                                'longestStreak': 0,
                              },
                            );
                          },
                          child: const Text('Test First Step Achievement (1 habit)'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Test achievement checking with sample data
                            final currentUser = FirebaseAuth.instance.currentUser;
                            final userId = currentUser?.uid ?? 'test_user_id';
                            
                            context.read<AchievementCubit>().checkAndUnlockAchievements(
                              userId,
                              {
                                'totalHabits': 1,
                                'totalCompletions': 0,
                                'currentStreak': 0,
                                'longestStreak': 0,
                              },
                            );
                          },
                          child: const Text('Test Achievement Check (1 habit)'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Test achievement checking with sample data
                            final currentUser = FirebaseAuth.instance.currentUser;
                            final userId = currentUser?.uid ?? 'test_user_id';
                            
                            context.read<AchievementCubit>().checkAndUnlockAchievements(
                              userId,
                              {
                                'totalHabits': 5,
                                'totalCompletions': 10,
                                'currentStreak': 3,
                                'longestStreak': 7,
                              },
                            );
                          },
                          child: const Text('Test Achievement Check (5 habits, 10 completions)'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Test achievement checking with sample data
                            final currentUser = FirebaseAuth.instance.currentUser;
                            final userId = currentUser?.uid ?? 'test_user_id';
                            
                            context.read<AchievementCubit>().checkAndUnlockAchievements(
                              userId,
                              {
                                'totalHabits': 10,
                                'totalCompletions': 100,
                                'currentStreak': 30,
                                'longestStreak': 30,
                              },
                            );
                          },
                          child: const Text('Test Achievement Check (10 habits, 100 completions, 30 day streak)'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Test achievement checking with sample data
                            final currentUser = FirebaseAuth.instance.currentUser;
                            final userId = currentUser?.uid ?? 'test_user_id';
                            
                            context.read<AchievementCubit>().checkAndUnlockAchievements(
                              userId,
                              {
                                'totalHabits': 20,
                                'totalCompletions': 500,
                                'currentStreak': 60,
                                'longestStreak': 60,
                              },
                            );
                          },
                          child: const Text('Test Achievement Check (20 habits, 500 completions, 60 day streak)'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Test special achievements
                            final currentUser = FirebaseAuth.instance.currentUser;
                            final userId = currentUser?.uid ?? 'test_user_id';
                            
                            context.read<AchievementCubit>().checkAndUnlockAchievements(
                              userId,
                              {
                                'totalHabits': 5,
                                'totalCompletions': 50,
                                'currentStreak': 7,
                                'longestStreak': 7,
                                'weeklyCompletions': 35,
                                'weeklyTotal': 5,
                                'completionHour': 5, // Early bird
                              },
                            );
                          },
                          child: const Text('Test Special Achievements (Early Bird, Perfect Week)'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementTile(achievement) {
    return ListTile(
      leading: Icon(
        Icons.star,
        color: achievement.isUnlocked ? Colors.amber : Colors.grey,
      ),
      title: Text(achievement.title),
      subtitle: Text(achievement.description),
      trailing: Text(
        '${achievement.points} pts',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      tileColor: achievement.isUnlocked ? Colors.green.withOpacity(0.1) : null,
    );
  }
}