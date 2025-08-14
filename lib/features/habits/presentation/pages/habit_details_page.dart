// File: features/habits/presentation/pages/habit_details_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/habit.dart';
import '../cubit/habit_cubit.dart';
import '../cubit/habit_state.dart';
import '../widgets/habit_progress_chart.dart';
import '../widgets/streak_indicator.dart';
import 'add_habit_page.dart';

class HabitDetailsPage extends StatefulWidget {
  final Habit habit;

  const HabitDetailsPage({super.key, required this.habit});

  @override
  State<HabitDetailsPage> createState() => _HabitDetailsPageState();
}

class _HabitDetailsPageState extends State<HabitDetailsPage> {
  late Habit currentHabit;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    currentHabit = widget.habit;
    _loadHabitHistory();
  }

  void _loadHabitHistory() {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));
    
    context.read<HabitCubit>().loadHabitHistory(
      habitId: currentHabit.id,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocListener<HabitCubit, HabitState>(
        listener: (context, state) {
          if (state is HabitCompleteSuccess) {
            setState(() => currentHabit = state.completedHabit);
            _showSuccessSnackBar(state.message);
          } else if (state is HabitUncompleteSuccess) {
            setState(() => currentHabit = state.uncompletedHabit);
          } else if (state is HabitDeleteSuccess) {
            Navigator.of(context).pop();
            _showSuccessSnackBar('Habit deleted successfully');
          } else if (state is HabitToggleActiveSuccess) {
            setState(() => currentHabit = state.toggledHabit);
            _showSuccessSnackBar(state.message);
          } else if (state is HabitUpdateSuccess) {
            setState(() => currentHabit = state.updatedHabit);
            _showSuccessSnackBar('Habit updated successfully');
          } else if (state is HabitCompleteError) {
            _showErrorSnackBar(state.message);
          } else if (state is HabitDeleteError) {
            _showErrorSnackBar(state.message);
          }
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            _buildSliverAppBar(),
            
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats Cards
                    _buildQuickStats(),
                    
                    const SizedBox(height: 24),
                    
                    // Progress Chart
                    _buildProgressSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Habit Details
                    _buildDetailsSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    _buildActionButtons(),
                    
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: _showOptionsMenu,
          icon: const Icon(Icons.more_vert, color: Colors.white),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(currentHabit.category),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getCategoryLabel(currentHabit.category),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    currentHabit.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Status
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: currentHabit.isActive ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentHabit.isActive ? 'Active' : 'Paused',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        // Current Streak
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department,
            title: 'Current Streak',
            value: '${currentHabit.currentStreak}',
            subtitle: 'days',
            color: Colors.orange,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Longest Streak
        Expanded(
          child: _buildStatCard(
            icon: Icons.emoji_events,
            title: 'Best Streak',
            value: '${currentHabit.longestStreak}',
            subtitle: 'days',
            color: Colors.amber,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Total Completions
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            title: 'Total',
            value: '${currentHabit.totalCompletions}',
            subtitle: 'times',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
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
          const Text(
            '30-Day Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          /*
          // Progress Chart
          BlocBuilder<HabitCubit, HabitState>(
            builder: (context, state) {
              if (state is HabitHistoryLoaded && state.habitId == currentHabit.id) {
                return HabitProgressChart(
                  history: state.history,
                  startDate: state.startDate,
                  endDate: state.endDate,
                );
              }
              
              if (state is HabitLoading) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              return const SizedBox(
                height: 100,
                child: Center(
                  child: Text('No progress data available'),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          */
          // Today's Status
          _buildTodayStatus(),
        ],
      ),
    );
  }

  Widget _buildTodayStatus() {
    final isCompletedToday = currentHabit.isCompletedToday();
    final shouldShowToday = currentHabit.shouldShowToday();
    
    if (!shouldShowToday) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600]),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Not scheduled for today',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompletedToday 
            ? Colors.green.withOpacity(0.1) 
            : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompletedToday 
              ? Colors.green.withOpacity(0.3) 
              : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompletedToday ? Colors.green : AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isCompletedToday ? Icons.check : Icons.play_arrow,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompletedToday ? 'Completed Today!' : 'Ready for Today',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCompletedToday ? Colors.green : AppColors.primary,
                  ),
                ),
                Text(
                  isCompletedToday 
                      ? 'Great job! Keep the streak going.'
                      : 'Mark as complete when you finish.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          
          // Complete/Uncomplete Button
          GestureDetector(
            onTap: () {
              if (isCompletedToday) {
                context.read<HabitCubit>().uncompleteHabit(currentHabit.id);
              } else {
                context.read<HabitCubit>().completeHabit(currentHabit.id);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isCompletedToday ? Colors.green : AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isCompletedToday ? 'Undo' : 'Complete',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
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
          const Text(
            'Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          if (currentHabit.description != null && currentHabit.description!.isNotEmpty)
            _buildDetailRow(
              icon: Icons.description,
              title: 'Description',
              value: currentHabit.description!,
            ),
          
          // Frequency
          _buildDetailRow(
            icon: Icons.schedule,
            title: 'Frequency',
            value: _getFrequencyDescription(),
          ),
          
          // Target Count
          if (currentHabit.targetCount > 1)
            _buildDetailRow(
              icon: Icons.check_circle_outline,
              title: 'Daily Target',
              value: '${currentHabit.targetCount} times per day',
            ),
          
          // Created Date
          _buildDetailRow(
            icon: Icons.calendar_today,
            title: 'Created',
            value: _formatDate(currentHabit.createdAt),
          ),
          
          // Last Completed
          if (currentHabit.lastCompletedAt != null)
            _buildDetailRow(
              icon: Icons.check_circle_outline,
              title: 'Last Completed',
              value: _formatDate(currentHabit.lastCompletedAt!),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Edit Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddHabitPage(habitToEdit: currentHabit),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Habit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Pause/Resume Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<HabitCubit>().toggleHabitActive(currentHabit.id);
            },
            icon: Icon(currentHabit.isActive ? Icons.pause : Icons.play_arrow),
            label: Text(currentHabit.isActive ? 'Pause Habit' : 'Resume Habit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: currentHabit.isActive ? Colors.orange : Colors.green,
              side: BorderSide(
                color: currentHabit.isActive ? Colors.orange : Colors.green,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Delete Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _showDeleteConfirmation,
            icon: const Icon(Icons.delete),
            label: const Text('Delete Habit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Habit'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddHabitPage(habitToEdit: currentHabit),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(currentHabit.isActive ? Icons.pause : Icons.play_arrow),
                title: Text(currentHabit.isActive ? 'Pause Habit' : 'Resume Habit'),
                onTap: () {
                  Navigator.pop(context);
                  context.read<HabitCubit>().toggleHabitActive(currentHabit.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Progress'),
                onTap: () {
                  Navigator.pop(context);
                  _shareProgress();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Habit', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Habit'),
          content: Text(
            'Are you sure you want to delete "${currentHabit.title}"? '
            'This action cannot be undone and all progress will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<HabitCubit>().deleteHabit(currentHabit.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _shareProgress() {
    final progressText = '''
🎯 ${currentHabit.title}

📊 Progress Update:
🔥 Current Streak: ${currentHabit.currentStreak} days
🏆 Best Streak: ${currentHabit.longestStreak} days
✅ Total Completions: ${currentHabit.totalCompletions}

Keep building great habits! 💪
    ''';
    
    // You can implement actual sharing here using share_plus package
    // Share.share(progressText);
    
    _showSuccessSnackBar('Progress copied to clipboard!');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getCategoryIcon(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return Icons.favorite;
      case HabitCategory.productivity:
        return Icons.work;
      case HabitCategory.learning:
        return Icons.school;
      case HabitCategory.social:
        return Icons.people;
      case HabitCategory.personal:
        return Icons.person;
      case HabitCategory.finance:
        return Icons.attach_money;
    }
  }

  String _getCategoryLabel(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return 'Health';
      case HabitCategory.productivity:
        return 'Productivity';
      case HabitCategory.learning:
        return 'Learning';
      case HabitCategory.social:
        return 'Social';
      case HabitCategory.personal:
        return 'Personal';
      case HabitCategory.finance:
        return 'Finance';
    }
  }

  String _getFrequencyDescription() {
    switch (currentHabit.frequency) {
      case HabitFrequency.daily:
        return 'Every day';
      case HabitFrequency.weekly:
        if (currentHabit.customDays.isEmpty) return 'Weekly';
        return 'Weekly on ${currentHabit.customDays.join(", ")}';
      case HabitFrequency.monthly:
        return 'Monthly';
      case HabitFrequency.custom:
        return 'Custom schedule: ${currentHabit.customDays.join(", ")}';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    
    return '${date.day}/${date.month}/${date.year}';
  }
}