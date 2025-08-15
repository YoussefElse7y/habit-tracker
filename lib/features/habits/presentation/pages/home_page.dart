// File: features/habits/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/habit.dart';
import '../cubit/habit_cubit.dart';
import '../cubit/habit_state.dart';
import 'add_habit_page.dart';
import 'habit_details_page.dart';
import 'achievements_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../goals/presentation/cubit/goals_cubit.dart';
import '../../../goals/presentation/cubit/goals_state.dart';
import '../../../goals/presentation/pages/add_goal_page.dart';
import '../../../goals/domain/entities/goal.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  // Keep the widget alive to avoid rebuilding
  @override
  bool get wantKeepAlive => true;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Load initial data only once
    if (!_isInitialized) {
      _loadInitialData();
      _isInitialized = true;
    }
  }

  Future<void> _loadInitialData() async {
    try {
      // Load data in parallel for better performance
      await Future.wait([
        context.read<HabitCubit>().loadTodaysHabits(),
        context.read<HabitCubit>().loadAllHabits(),
        context.read<GoalsCubit>().loadGoals(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    try {
      await context.read<HabitCubit>().refreshAllData();
      await context.read<GoalsCubit>().loadGoals();
    } catch (e) {
      // Error is handled by the cubit states
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(child: _AppBarSection()),

              // Main Content
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Progress Card
                    _ProgressCard(),

                    const SizedBox(height: 24),

                    // Today's Habits Section
                    _TodayHabitsSection(),

                    const SizedBox(height: 24),

                    // Goals Section
                    _GoalsSection(),

                    const SizedBox(height: 100), // Bottom padding for FAB
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => _navigateToAddHabit(),
        child: Container(
          margin: EdgeInsets.only(bottom: 10, right: 10),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.habitCompleted,
                AppColors.secondaryLight,
              ],
              
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 5,
            ),
          ),
          child: const Icon(
            Icons.add,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _navigateToAddHabit() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddHabitPage()),
    );
  }
}

// Extracted App Bar as separate widget for better organization
class _AppBarSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      height: 100,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getFormattedDate(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hello, Susy!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          _ProfileButton(),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

// Extracted Profile and Achievements Buttons
class _ProfileButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Achievements Button
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AchievementsPage()),
          ),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events,
              color: AppColors.secondary,
              size: 24,
            ),
          ),
        ),
        // Profile Button
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

// Extracted Progress Card with fixed calculation
class _ProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitCubit, HabitState>(
      builder: (context, state) {
        final todaysHabits = context.read<HabitCubit>().todaysHabits;

        final totalHabits = todaysHabits.length;
        final completedHabits =
            todaysHabits.where((habit) => habit.isCompletedToday()).length;

        final progress = totalHabits > 0 ? completedHabits / totalHabits : 0.0;
        final percentage = (progress * 100).round();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _ProgressCircle(progress: progress, percentage: percentage),
              const SizedBox(width: 24),
              _ProgressText(completed: completedHabits, total: totalHabits),
              _CalendarIcon(),
            ],
          ),
        );
      },
    );
  }
}

// Progress Circle Widget
class _ProgressCircle extends StatelessWidget {
  final double progress;
  final int percentage;

  const _ProgressCircle({
    required this.progress,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          Center(
            child: Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Progress Text Widget
class _ProgressText extends StatelessWidget {
  final int completed;
  final int total;

  const _ProgressText({
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$completed of $total habits',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'completed today!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Calendar Icon Widget
class _CalendarIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.calendar_today,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

// Today's Habits Section
class _TodayHabitsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _SectionHeader(
            title: 'Today Habit',
            actionText: 'See all',
            onActionPressed: () {
              // Navigate to all habits view
              // TODO: Implement navigation to all habits
            },
          ),
          const SizedBox(height: 16),
          _TodayHabitsList(),
        ],
      ),
    );
  }
}

// Today's Habits List
class _TodayHabitsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitCubit, HabitState>(
      builder: (context, state) {
        // Show loading only if no habits are cached
        if (state is HabitLoading &&
            context.read<HabitCubit>().todaysHabits.isEmpty) {
          return const _LoadingWidget();
        }

        if (state is HabitTodayEmpty) {
          return _EmptyStateWidget(message: state.message);
        }

        if (state is HabitError) {
          return _ErrorWidget(
            message: state.message,
            onRetry: () => context.read<HabitCubit>().loadTodaysHabits(),
          );
        }

        final todaysHabits = context.read<HabitCubit>().todaysHabits;

        if (todaysHabits.isEmpty) {
          return const _EmptyStateWidget(message: 'No habits for today');
        }

        return Column(
          children: todaysHabits
              .map((habit) => _TodayHabitCard(habit: habit))
              .toList(),
        );
      },
    );
  }
}

// Today Habit Card
class _TodayHabitCard extends StatelessWidget {
  final Habit habit;

  const _TodayHabitCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final isCompleted = habit.isCompletedToday();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isCompleted ? AppColors.secondary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.secondary.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              habit.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isCompleted ? AppColors.secondary : Colors.black87,
              ),
            ),
          ),
          _CompleteButton(habit: habit),
          const SizedBox(width: 8),
          _MoreOptionsButton(habit: habit),
        ],
      ),
    );
  }
}

// Complete Button
class _CompleteButton extends StatelessWidget {
  final Habit habit;

  const _CompleteButton({required this.habit});

  @override
  Widget build(BuildContext context) {
    final isCompleted = habit.isCompletedToday();

    return GestureDetector(
      onTap: () {
        if (isCompleted) {
          context.read<HabitCubit>().uncompleteHabit(habit.id);
        } else {
          context.read<HabitCubit>().completeHabit(habit.id);
        }
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.secondary : Colors.transparent,
          border: Border.all(
            color: isCompleted
                ? AppColors.secondary
                : Colors.grey.withOpacity(0.4),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

// More Options Button
class _MoreOptionsButton extends StatelessWidget {
  final Habit habit;

  const _MoreOptionsButton({required this.habit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showHabitOptions(context, habit),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.more_horiz,
          color: Colors.grey[600],
          size: 20,
        ),
      ),
    );
  }

  void _showHabitOptions(BuildContext context, Habit habit) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _HabitOptionsBottomSheet(habit: habit),
    );
  }
}

// Goals Section
class _GoalsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _SectionHeader(
            title: 'Your Goals',
            actionText: 'Add Goal',
            onActionPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddGoalPage()),
            ),
          ),
          const SizedBox(height: 16),
          _GoalsList(),
        ],
      ),
    );
  }
}

// Goals List
class _GoalsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoalsCubit, GoalsState>(
      builder: (context, state) {
        if (state is GoalsLoading) {
          return const _LoadingWidget();
        }

        if (state is GoalsEmpty) {
          return const _EmptyGoalsWidget();
        }

        if (state is GoalsError) {
          return _ErrorWidget(
            message: state.message,
            onRetry: () => context.read<GoalsCubit>().loadGoals(),
          );
        }

        final goals = context.read<GoalsCubit>().currentGoals;

        if (goals.isEmpty) {
          return const _EmptyGoalsWidget();
        }

        // Show only first 3 goals in home page
        final displayGoals = goals.take(3).toList();

        return Column(
          children: displayGoals
              .map((goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GoalCard(goal: goal),
                  ))
              .toList(),
        );
      },
    );
  }
}

// Reusable Section Header
class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback? onActionPressed;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        TextButton(
          onPressed: onActionPressed,
          child: Text(
            actionText,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// Loading Widget
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// Empty State Widget
class _EmptyStateWidget extends StatelessWidget {
  final String message;

  const _EmptyStateWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.track_changes,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Empty Goals Widget
class _EmptyGoalsWidget extends StatelessWidget {
  const _EmptyGoalsWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.flag,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No goals yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first goal to get started!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// Error Widget
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isNetworkError = message.contains('permission') ||
        message.contains('PERMISSION_DENIED') ||
        message.contains('network') ||
        message.contains('connection');

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            isNetworkError ? Icons.cloud_off : Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            isNetworkError ? 'Connection Error' : 'Something went wrong',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isNetworkError
                ? 'Please check your internet connection and try again.'
                : message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// Goal Card
class _GoalCard extends StatelessWidget {
  final Goal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GoalHeader(goal: goal),
          const SizedBox(height: 12),
          _GoalProgressBar(goal: goal),
          const SizedBox(height: 12),
          _GoalProgressInfo(goal: goal),
        ],
      ),
    );
  }
}

// Goal Header
class _GoalHeader extends StatelessWidget {
  final Goal goal;

  const _GoalHeader({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (goal.iconName != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _parseColor(goal.colorHex).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getGoalIconData(goal.iconName!),
                    size: 18,
                    color: _parseColor(goal.colorHex),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        _GoalActionButtons(goal: goal),
      ],
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null) return AppColors.primary;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }
}

// Habit Options Bottom Sheet
class _HabitOptionsBottomSheet extends StatelessWidget {
  final Habit habit;

  const _HabitOptionsBottomSheet({required this.habit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('View Details'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HabitDetailsPage(habit: habit),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Habit'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to edit habit
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit habit feature coming soon!'),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              habit.isActive ? Icons.pause : Icons.play_arrow,
            ),
            title: Text(habit.isActive ? 'Pause Habit' : 'Resume Habit'),
            onTap: () {
              Navigator.pop(context);
              context.read<HabitCubit>().toggleHabitActive(habit.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title:
                const Text('Delete Habit', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, habit);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Habit'),
          content: Text(
            'Are you sure you want to delete "${habit.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<HabitCubit>().deleteHabit(habit.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

// Goal Options Bottom Sheet
class _GoalOptionsBottomSheet extends StatelessWidget {
  final Goal goal;

  const _GoalOptionsBottomSheet({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Goal'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit goal feature coming soon!'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title:
                const Text('Delete Goal', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteGoalConfirmation(context, goal);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteGoalConfirmation(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Goal'),
          content: Text(
            'Are you sure you want to delete "${goal.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<GoalsCubit>().deleteGoal(goal.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

Color _parseColor(String? colorHex) {
  if (colorHex == null) return AppColors.primary;
  try {
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  } catch (e) {
    return AppColors.primary;
  }
}

IconData _getGoalIconData(String iconName) {
  const iconMap = {
    'book': Icons.book,
    'fitness_center': Icons.fitness_center,
    'local_drink': Icons.local_drink,
    'bedtime': Icons.bedtime,
    'school': Icons.school,
    'work': Icons.work,
    'favorite': Icons.favorite,
    'sports_soccer': Icons.sports_soccer,
    'music_note': Icons.music_note,
    'palette': Icons.palette,
  };

  return iconMap[iconName] ?? Icons.star;
}

// Goal Action Buttons
class _GoalActionButtons extends StatelessWidget {
  final Goal goal;

  const _GoalActionButtons({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Decrement button
        _GoalActionButton(
          icon: Icons.remove,
          isEnabled: goal.currentValue > 0,
          onTap: goal.currentValue > 0
              ? () => context.read<GoalsCubit>().decrementGoalProgress(goal.id)
              : null,
        ),

        const SizedBox(width: 8),

        // Increment button
        _GoalActionButton(
          icon: Icons.add,
          isEnabled: goal.currentValue < goal.targetValue,
          isIncrement: true,
          onTap: goal.currentValue < goal.targetValue
              ? () => context.read<GoalsCubit>().incrementGoalProgress(goal.id)
              : null,
        ),

        const SizedBox(width: 8),

        // More options
        GestureDetector(
          onTap: () => _showGoalOptions(context, goal),
          child: Icon(
            Icons.more_horiz,
            color: Colors.grey[600],
            size: 20,
          ),
        ),
      ],
    );
  }

  void _showGoalOptions(BuildContext context, Goal goal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _GoalOptionsBottomSheet(goal: goal),
    );
  }
}

// Goal Action Button
class _GoalActionButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final bool isIncrement;
  final VoidCallback? onTap;

  const _GoalActionButton({
    required this.icon,
    required this.isEnabled,
    this.isIncrement = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isEnabled
              ? (isIncrement ? AppColors.primary : Colors.grey[200])
              : (isIncrement ? Colors.grey[300] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled
              ? (isIncrement ? Colors.white : Colors.grey[700])
              : Colors.grey[400],
        ),
      ),
    );
  }
}

// Goal Progress Bar
class _GoalProgressBar extends StatelessWidget {
  final Goal goal;

  const _GoalProgressBar({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: goal.progress,
        child: Container(
          decoration: BoxDecoration(
            color: _parseColor(goal.colorHex),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null) return AppColors.primary;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }
}

// Goal Progress Info
class _GoalProgressInfo extends StatelessWidget {
  final Goal goal;

  const _GoalProgressInfo({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${goal.currentValue} of ${goal.targetValue} ${goal.frequencyText.toLowerCase()}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: goal.isCompleted
                ? Colors.green.withOpacity(0.1)
                : _parseColor(goal.colorHex).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            goal.isCompleted ? 'Completed!' : goal.frequencyText,
            style: TextStyle(
              fontSize: 12,
              color:
                  goal.isCompleted ? Colors.green : _parseColor(goal.colorHex),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
