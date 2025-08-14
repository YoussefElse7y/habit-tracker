// File: features/habits/presentation/pages/add_habit_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habit_tracker_app/features/habits/data/models/habit_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/habit.dart';
import '../cubit/habit_cubit.dart';
import '../cubit/habit_state.dart';

class AddHabitPage extends StatefulWidget {
  final Habit? habitToEdit; // For editing existing habits

  const AddHabitPage({super.key, this.habitToEdit});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  HabitCategory _selectedCategory = HabitCategory.personal;
  HabitFrequency _selectedFrequency = HabitFrequency.daily;
  List<String> _selectedDays = [];
  int _targetCount = 1;
  bool _isLoading = false;

  // Days of the week for selection
  final List<String> _weekDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  final Map<String, String> _dayLabels = {
    'monday': 'Mon',
    'tuesday': 'Tue',
    'wednesday': 'Wed',
    'thursday': 'Thu',
    'friday': 'Fri',
    'saturday': 'Sat',
    'sunday': 'Sun',
  };

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.habitToEdit != null) {
      final habit = widget.habitToEdit!;
      _titleController.text = habit.title;
      _descriptionController.text = habit.description ?? '';
      _selectedCategory = habit.category;
      _selectedFrequency = habit.frequency;
      _selectedDays = List.from(habit.customDays);
      _targetCount = habit.targetCount;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.black87),
        ),
        title: Text(
          widget.habitToEdit != null ? 'Edit Habit' : 'Add New Habit',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<HabitCubit, HabitState>(
        listener: (context, state) {
          if (state is HabitAddingLoading) {
            setState(() => _isLoading = true);
          } else if (state is HabitAddSuccess) {
            setState(() => _isLoading = false);
            _showSuccessSnackBar('Habit added successfully!');
            Navigator.pop(context);
          } else if (state is HabitUpdateSuccess) {
            setState(() => _isLoading = false);
            _showSuccessSnackBar('Habit updated successfully!');
            Navigator.pop(context);
          } else if (state is HabitAddError) {
            setState(() => _isLoading = false);
            _showErrorSnackBar(state.message);
          } else if (state is HabitUpdateError) {
            setState(() => _isLoading = false);
            _showErrorSnackBar(state.message);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Field
                _buildSectionTitle('Habit Title'),
                const SizedBox(height: 8),
                _buildTitleField(),
                
                const SizedBox(height: 24),
                
                // Description Field
                _buildSectionTitle('Description (Optional)'),
                const SizedBox(height: 8),
                _buildDescriptionField(),
                
                const SizedBox(height: 24),
                
                // Category Selection
                _buildSectionTitle('Category'),
                const SizedBox(height: 12),
                _buildCategorySelection(),
                
                const SizedBox(height: 24),
                
                // Frequency Selection
                _buildSectionTitle('Frequency'),
                const SizedBox(height: 12),
                _buildFrequencySelection(),
                
                const SizedBox(height: 16),
                
                // Custom Days (if weekly or custom)
                if (_selectedFrequency == HabitFrequency.weekly || 
                    _selectedFrequency == HabitFrequency.custom)
                  _buildCustomDaysSelection(),
                
                const SizedBox(height: 24),
                
                // Target Count
                _buildSectionTitle('Daily Target'),
                const SizedBox(height: 8),
                _buildTargetCountField(),
                
                const SizedBox(height: 40),
                
                // Save Button
                _buildSaveButton(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        hintText: 'Enter habit title',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a habit title';
        }
        if (value.trim().length < 3) {
          return 'Title must be at least 3 characters long';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Add a description for your habit',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: HabitCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 18,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  _getCategoryLabel(category),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrequencySelection() {
    return Column(
      children: HabitFrequency.values.map((frequency) {
        final isSelected = _selectedFrequency == frequency;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedFrequency = frequency;
              if (frequency != HabitFrequency.weekly && 
                  frequency != HabitFrequency.custom) {
                _selectedDays.clear();
              }
            }),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getFrequencyIcon(frequency),
                    color: isSelected ? AppColors.primary : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFrequencyLabel(frequency),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.primary : Colors.black87,
                          ),
                        ),
                        Text(
                          _getFrequencyDescription(frequency),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomDaysSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Days',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weekDays.map((day) {
            final isSelected = _selectedDays.contains(day);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedDays.remove(day);
                  } else {
                    _selectedDays.add(day);
                  }
                });
              },
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    _dayLabels[day]!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTargetCountField() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'How many times per day?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _targetCount > 1 
                    ? () => setState(() => _targetCount--) 
                    : null,
                icon: const Icon(Icons.remove),
                color: AppColors.primary,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _targetCount.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: _targetCount < 10 
                    ? () => setState(() => _targetCount++) 
                    : null,
                icon: const Icon(Icons.add),
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveHabit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                widget.habitToEdit != null ? 'Update Habit' : 'Create Habit',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _saveHabit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate custom days for weekly/custom frequency
    if ((_selectedFrequency == HabitFrequency.weekly || 
         _selectedFrequency == HabitFrequency.custom) && 
        _selectedDays.isEmpty) {
      _showErrorSnackBar('Please select at least one day');
      return;
    }

    if (widget.habitToEdit != null) {
      // Update existing habit
      final updatedHabit = widget.habitToEdit!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        frequency: _selectedFrequency,
        customDays: _selectedDays,
        targetCount: _targetCount,
        updatedAt: DateTime.now(),
      );
      
      // You'll need to implement this method in your cubit
      // context.read<HabitCubit>().updateHabit(updatedHabit);
    } else {
      // Create new habit
      context.read<HabitCubit>().addHabit(
        userId: 'current_user_id', // Replace with actual user ID
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        frequency: _selectedFrequency,
        customDays: _selectedDays,
        targetCount: _targetCount,
      );
    }
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

  IconData _getFrequencyIcon(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return Icons.today;
      case HabitFrequency.weekly:
        return Icons.calendar_view_week;
      case HabitFrequency.monthly:
        return Icons.calendar_view_month;
      case HabitFrequency.custom:
        return Icons.tune;
    }
  }

  String _getFrequencyLabel(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.monthly:
        return 'Monthly';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }

  String _getFrequencyDescription(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Every day';
      case HabitFrequency.weekly:
        return 'Select specific days of the week';
      case HabitFrequency.monthly:
        return 'Once per month';
      case HabitFrequency.custom:
        return 'Choose your own schedule';
    }
  }
}