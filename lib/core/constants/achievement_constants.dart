// File: core/constants/achievement_constants.dart

import '../../features/habits/domain/entities/achievement.dart';

class AchievementConstants {
  AchievementConstants._();

  static const List<Achievement> streakAchievements = [
    Achievement(
      id: 'streak_3_days',
      title: 'Getting Started',
      description: 'Maintain a 3-day streak',
      iconName: 'flame',
      type: AchievementType.streak,
      tier: AchievementTier.bronze,
      requirement: 3,
      points: 10,
      category: 'streak',
    ),
    Achievement(
      id: 'streak_7_days',
      title: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      iconName: 'flame',
      type: AchievementType.streak,
      tier: AchievementTier.bronze,
      requirement: 7,
      points: 25,
      category: 'streak',
    ),
    Achievement(
      id: 'streak_14_days',
      title: 'Fortnight Fighter',
      description: 'Maintain a 14-day streak',
      iconName: 'flame',
      type: AchievementType.streak,
      tier: AchievementTier.silver,
      requirement: 14,
      points: 50,
      category: 'streak',
    ),
    Achievement(
      id: 'streak_30_days',
      title: 'Monthly Master',
      description: 'Maintain a 30-day streak',
      iconName: 'flame',
      type: AchievementType.streak,
      tier: AchievementTier.silver,
      requirement: 30,
      points: 100,
      category: 'streak',
    ),
    Achievement(
      id: 'streak_60_days',
      title: 'Dedication Demon',
      description: 'Maintain a 60-day streak',
      iconName: 'flame',
      type: AchievementType.streak,
      tier: AchievementTier.gold,
      requirement: 60,
      points: 200,
      category: 'streak',
    ),
    Achievement(
      id: 'streak_100_days',
      title: 'Century Club',
      description: 'Maintain a 100-day streak',
      iconName: 'flame',
      type: AchievementType.streak,
      tier: AchievementTier.gold,
      requirement: 100,
      points: 500,
      category: 'streak',
    ),
    Achievement(
      id: 'streak_365_days',
      title: 'Year of Excellence',
      description: 'Maintain a 365-day streak',
      iconName: 'flame',
      type: AchievementType.streak,
      tier: AchievementTier.platinum,
      requirement: 365,
      points: 1000,
      category: 'streak',
    ),
  ];

  static const List<Achievement> completionAchievements = [
    Achievement(
      id: 'complete_10_habits',
      title: 'Habit Starter',
      description: 'Complete 10 habits',
      iconName: 'check_circle',
      type: AchievementType.completion,
      tier: AchievementTier.bronze,
      requirement: 10,
      points: 15,
      category: 'completion',
    ),
    Achievement(
      id: 'complete_50_habits',
      title: 'Habit Builder',
      description: 'Complete 50 habits',
      iconName: 'check_circle',
      type: AchievementType.completion,
      tier: AchievementTier.bronze,
      requirement: 50,
      points: 35,
      category: 'completion',
    ),
    Achievement(
      id: 'complete_100_habits',
      title: 'Habit Enthusiast',
      description: 'Complete 100 habits',
      iconName: 'check_circle',
      type: AchievementType.completion,
      tier: AchievementTier.silver,
      requirement: 100,
      points: 75,
      category: 'completion',
    ),
    Achievement(
      id: 'complete_500_habits',
      title: 'Habit Veteran',
      description: 'Complete 500 habits',
      iconName: 'check_circle',
      type: AchievementType.completion,
      tier: AchievementTier.silver,
      requirement: 500,
      points: 150,
      category: 'completion',
    ),
    Achievement(
      id: 'complete_1000_habits',
      title: 'Habit Master',
      description: 'Complete 1000 habits',
      iconName: 'check_circle',
      type: AchievementType.completion,
      tier: AchievementTier.gold,
      requirement: 1000,
      points: 300,
      category: 'completion',
    ),
    Achievement(
      id: 'complete_10000_habits',
      title: 'Habit Legend',
      description: 'Complete 10000 habits',
      iconName: 'check_circle',
      type: AchievementType.completion,
      tier: AchievementTier.platinum,
      requirement: 10000,
      points: 1000,
      category: 'completion',
    ),
  ];

  static const List<Achievement> milestoneAchievements = [
    Achievement(
      id: 'first_habit',
      title: 'First Step',
      description: 'Create your first habit',
      iconName: 'star',
      type: AchievementType.milestone,
      tier: AchievementTier.bronze,
      requirement: 1,
      points: 5,
      category: 'milestone',
    ),
    Achievement(
      id: 'five_habits',
      title: 'Habit Collector',
      description: 'Create 5 different habits',
      iconName: 'star',
      type: AchievementType.milestone,
      tier: AchievementTier.bronze,
      requirement: 5,
      points: 20,
      category: 'milestone',
    ),
    Achievement(
      id: 'ten_habits',
      title: 'Habit Architect',
      description: 'Create 10 different habits',
      iconName: 'star',
      type: AchievementType.milestone,
      tier: AchievementTier.silver,
      requirement: 10,
      points: 40,
      category: 'milestone',
    ),
    Achievement(
      id: 'twenty_habits',
      title: 'Habit Designer',
      description: 'Create 20 different habits',
      iconName: 'star',
      type: AchievementType.milestone,
      tier: AchievementTier.silver,
      requirement: 20,
      points: 80,
      category: 'milestone',
    ),
    Achievement(
      id: 'fifty_habits',
      title: 'Habit Creator',
      description: 'Create 50 different habits',
      iconName: 'star',
      type: AchievementType.milestone,
      tier: AchievementTier.gold,
      requirement: 50,
      points: 200,
      category: 'milestone',
    ),
  ];

  static const List<Achievement> specialAchievements = [
    Achievement(
      id: 'perfect_week',
      title: 'Perfect Week',
      description: 'Complete all habits for 7 consecutive days',
      iconName: 'trophy',
      type: AchievementType.special,
      tier: AchievementTier.gold,
      requirement: 7,
      points: 150,
      category: 'special',
    ),
    Achievement(
      id: 'perfect_month',
      title: 'Perfect Month',
      description: 'Complete all habits for 30 consecutive days',
      iconName: 'trophy',
      type: AchievementType.special,
      tier: AchievementTier.platinum,
      requirement: 30,
      points: 500,
      category: 'special',
    ),
    Achievement(
      id: 'early_bird',
      title: 'Early Bird',
      description: 'Complete a habit before 6 AM',
      iconName: 'wb_sunny',
      type: AchievementType.special,
      tier: AchievementTier.bronze,
      requirement: 1,
      points: 25,
      category: 'special',
    ),
    Achievement(
      id: 'night_owl',
      title: 'Night Owl',
      description: 'Complete a habit after 10 PM',
      iconName: 'nightlight',
      type: AchievementType.special,
      tier: AchievementTier.bronze,
      requirement: 1,
      points: 25,
      category: 'special',
    ),
    Achievement(
      id: 'weekend_warrior',
      title: 'Weekend Warrior',
      description: 'Complete habits on both Saturday and Sunday',
      iconName: 'weekend',
      type: AchievementType.special,
      tier: AchievementTier.silver,
      requirement: 2,
      points: 50,
      category: 'special',
    ),
    Achievement(
      id: 'holiday_hero',
      title: 'Holiday Hero',
      description: 'Complete habits on a major holiday',
      iconName: 'celebration',
      type: AchievementType.special,
      tier: AchievementTier.silver,
      requirement: 1,
      points: 75,
      category: 'special',
    ),
  ];

  static const List<Achievement> categoryAchievements = [
    Achievement(
      id: 'health_expert',
      title: 'Health Expert',
      description: 'Complete 100 health-related habits',
      iconName: 'favorite',
      type: AchievementType.milestone,
      tier: AchievementTier.silver,
      requirement: 100,
      points: 100,
      category: 'health',
    ),
    Achievement(
      id: 'productivity_guru',
      title: 'Productivity Guru',
      description: 'Complete 100 productivity-related habits',
      iconName: 'work',
      type: AchievementType.milestone,
      tier: AchievementTier.silver,
      requirement: 100,
      points: 100,
      category: 'productivity',
    ),
    Achievement(
      id: 'learning_champion',
      title: 'Learning Champion',
      description: 'Complete 100 learning-related habits',
      iconName: 'school',
      type: AchievementType.milestone,
      tier: AchievementTier.silver,
      requirement: 100,
      points: 100,
      category: 'learning',
    ),
    Achievement(
      id: 'social_butterfly',
      title: 'Social Butterfly',
      description: 'Complete 100 social-related habits',
      iconName: 'people',
      type: AchievementType.milestone,
      tier: AchievementTier.silver,
      requirement: 100,
      points: 100,
      category: 'social',
    ),
    Achievement(
      id: 'personal_development',
      title: 'Personal Development',
      description: 'Complete 100 personal development habits',
      iconName: 'person',
      type: AchievementType.milestone,
      tier: AchievementTier.silver,
      requirement: 100,
      points: 100,
      category: 'personal',
    ),
    Achievement(
      id: 'financial_wizard',
      title: 'Financial Wizard',
      description: 'Complete 100 finance-related habits',
      iconName: 'attach_money',
      type: AchievementType.milestone,
      tier: AchievementTier.silver,
      requirement: 100,
      points: 100,
      category: 'finance',
    ),
  ];

  static List<Achievement> get allAchievements => [
        ...streakAchievements,
        ...completionAchievements,
        ...milestoneAchievements,
        ...specialAchievements,
        ...categoryAchievements,
      ];

  static List<Achievement> getAchievementsByType(AchievementType type) {
    switch (type) {
      case AchievementType.streak:
        return streakAchievements;
      case AchievementType.completion:
        return completionAchievements;
      case AchievementType.milestone:
        return milestoneAchievements;
      case AchievementType.special:
        return specialAchievements;
    }
  }

  static List<Achievement> getAchievementsByTier(AchievementTier tier) {
    return allAchievements.where((achievement) => achievement.tier == tier).toList();
  }

  static List<Achievement> getAchievementsByCategory(String category) {
    return allAchievements.where((achievement) => achievement.category == category).toList();
  }

  static int get totalPointsAvailable {
    return allAchievements.fold<int>(0, (sum, achievement) => sum + achievement.points);
  }

  static Achievement? getAchievementById(String id) {
    try {
      return allAchievements.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }
}
