import 'package:equatable/equatable.dart';

enum GoalFrequency {
  daily,
  weekly,
  monthly,
  custom,
}

enum GoalStatus {
  active,
  completed,
  paused,
  cancelled,
}

class Goal extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final int targetValue;
  final int currentValue;
  final GoalFrequency frequency;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? targetDate;
  final String? iconName;
  final String? colorHex;

  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.targetValue,
    this.currentValue = 0,
    this.frequency = GoalFrequency.daily,
    this.status = GoalStatus.active,
    required this.createdAt,
    this.updatedAt,
    this.targetDate,
    this.iconName,
    this.colorHex,
  });

  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
  
  bool get isCompleted => currentValue >= targetValue;
  
  bool get isActive => status == GoalStatus.active;

  String get frequencyText {
    switch (frequency) {
      case GoalFrequency.daily:
        return 'Daily';
      case GoalFrequency.weekly:
        return 'Weekly';
      case GoalFrequency.monthly:
        return 'Monthly';
      case GoalFrequency.custom:
        return 'Custom';
    }
  }

  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    int? targetValue,
    int? currentValue,
    GoalFrequency? frequency,
    GoalStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? targetDate,
    String? iconName,
    String? colorHex,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      targetDate: targetDate ?? this.targetDate,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        targetValue,
        currentValue,
        frequency,
        status,
        createdAt,
        updatedAt,
        targetDate,
        iconName,
        colorHex,
      ];
}