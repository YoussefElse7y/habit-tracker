// File: features/habits/presentation/pages/test_achievements_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/achievement_constants.dart';
import '../cubit/achievement_cubit.dart';
import '../cubit/achievement_state.dart';
import '../widgets/achievement_card.dart';
import '../widgets/user_stats_card.dart';

/// Test page to verify the achievements system is working
/// This is a simplified version for testing purposes
class TestAchievementsPage extends StatefulWidget {
  const TestAchievementsPage({Key? key}) : super(key: key);

  @override
  State<TestAchievementsPage> createState() => _TestAchievementsPageState();
}

class _TestAchievementsPageState extends State<TestAchievementsPage> {
  @override
  void initState() {
    super.initState();
    // Load test data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AchievementCubit>().loadAllAchievements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Test Achievements',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: BlocBuilder<AchievementCubit, AchievementState>(
        builder: (context, state) {
          if (state is AchievementLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AchievementLoaded) {
            return _buildAchievementsList(state.achievements);
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
                ],
              ),
            );
          }

          return const Center(
            child: Text(
              'No achievements loaded yet',
              style: TextStyle(fontSize: 18),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementsList(List<Achievement> achievements) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return AchievementCard(
          achievement: achievement,
          isUnlocked: false, // For testing, show all as locked
          onTap: () => _showAchievementDetails(achievement),
        );
      },
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
}