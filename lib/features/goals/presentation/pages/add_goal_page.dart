import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/goal.dart';
import '../cubit/goals_cubit.dart';
import '../cubit/goals_state.dart';

class AddGoalPage extends StatefulWidget {
  const AddGoalPage({super.key});

  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetValueController = TextEditingController(text: '7');
  
  GoalFrequency _selectedFrequency = GoalFrequency.daily;
  DateTime? _targetDate;
  String? _selectedIcon;
  Color _selectedColor = AppColors.primary;

  final List<String> _availableIcons = [
    'book',
    'fitness_center',
    'local_drink',
    'bedtime',
    'school',
    'work',
    'favorite',
    'sports_soccer',
    'music_note',
    'palette',
  ];

  final List<Color> _availableColors = [
    AppColors.primary,
    AppColors.secondary,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.orange,
    Colors.teal,
    Colors.indigo,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Add Goal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          BlocConsumer<GoalsCubit, GoalsState>(
            listener: (context, state) {
              if (state is GoalAdded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Goal added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } else if (state is GoalsError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              return TextButton(
                onPressed: state is GoalsLoading ? null : _saveGoal,
                child: state is GoalsLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Save',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              _buildSection(
                title: 'Goal Details',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Goal Title',
                        hintText: 'e.g., Read 5 books this month',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a goal title';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add more details about your goal',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Target Section
              _buildSection(
                title: 'Target & Frequency',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _targetValueController,
                            decoration: const InputDecoration(
                              labelText: 'Target Value',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a target value';
                              }
                              final number = int.tryParse(value);
                              if (number == null || number <= 0) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<GoalFrequency>(
                            value: _selectedFrequency,
                            decoration: const InputDecoration(
                              labelText: 'Frequency',
                              border: OutlineInputBorder(),
                            ),
                            items: GoalFrequency.values.map((frequency) {
                              return DropdownMenuItem(
                                value: frequency,
                                child: Text(frequency.name.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFrequency = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Target Date (Optional)
                    ListTile(
                      leading: Icon(Icons.calendar_today, color: AppColors.primary),
                      title: Text(_targetDate == null 
                          ? 'Set Target Date (Optional)' 
                          : 'Target Date: ${_formatDate(_targetDate!)}'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _selectTargetDate,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Customization Section
              _buildSection(
                title: 'Customization',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose an Icon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableIcons.map((iconName) {
                        final isSelected = _selectedIcon == iconName;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIcon = isSelected ? null : iconName;
                            });
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppColors.primary 
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? AppColors.primary 
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _getIconData(iconName),
                              color: isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Choose a Color',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableColors.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black54 : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          child,
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'book':
        return Icons.book;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'local_drink':
        return Icons.local_drink;
      case 'bedtime':
        return Icons.bedtime;
      case 'school':
        return Icons.school;
      case 'work':
        return Icons.work;
      case 'favorite':
        return Icons.favorite;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'music_note':
        return Icons.music_note;
      case 'palette':
        return Icons.palette;
      default:
        return Icons.star;
    }
  }

  Future<void> _selectTargetDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        _targetDate = selectedDate;
      });
    }
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final targetValue = int.parse(_targetValueController.text);
      
      context.read<GoalsCubit>().addGoal(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        targetValue: targetValue,
        frequency: _selectedFrequency,
        targetDate: _targetDate,
        iconName: _selectedIcon,
        colorHex: '#${_selectedColor.value.toRadixString(16).substring(2)}',
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}