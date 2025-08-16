// File: features/habits/presentation/pages/test_achievements_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/achievement_cubit.dart';
import '../cubit/achievement_state.dart';

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
    context.read<AchievementCubit>().loadUserStats('test_user_id'); // Replace with actual user ID
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
                          _buildStatRow('Total Points', state.userStats.totalPoints.toString()),
                          _buildStatRow('Current Level', state.userStats.currentLevel.toString()),
                          _buildStatRow('Total Habits', state.userStats.totalHabits.toString()),
                          _buildStatRow('Active Habits', state.userStats.activeHabits.toString()),
                          _buildStatRow('Total Completions', state.userStats.totalCompletions.toString()),
                          _buildStatRow('Current Streak', state.userStats.currentStreak.toString()),
                          _buildStatRow('Longest Streak', state.userStats.longestStreak.toString()),
                          _buildStatRow('Total Achievements', state.userStats.totalAchievements.toString()),
                          _buildStatRow('Unlocked Achievements', state.userStats.unlockedAchievements.toString()),
                        ] else ...[
                          const Text('User stats not loaded'),
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
                            context.read<AchievementCubit>().loadUserStats('test_user_id');
                          },
                          child: const Text('Reload User Stats'),
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
                            // Test achievement checking with sample data
                            context.read<AchievementCubit>().checkAndUnlockAchievements(
                              'test_user_id',
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
                            context.read<AchievementCubit>().checkAndUnlockAchievements(
                              'test_user_id',
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