
import '../../domain/entities/habit.dart';

class HabitModel extends Habit {
  const HabitModel({
    required super.id,
    required super.userId,
    required super.title,
    super.description,
    required super.category,
    super.frequency,
    required super.createdAt,
    super.updatedAt,
    super.isActive,
    super.currentStreak,
    super.longestStreak,
    super.totalCompletions,
    super.lastCompletedAt,
    super.customDays,
    super.targetCount,
  });

  // Convert from Firestore document to HabitModel
  factory HabitModel.fromFirestore(Map<String, dynamic> doc) {
    return HabitModel(
      id: doc['id'] ?? '',
      userId: doc['userId'] ?? '',
      title: doc['title'] ?? '',
      description: doc['description'],
      category: _parseCategory(doc['category']),
      frequency: _parseFrequency(doc['frequency']),
      createdAt: _parseDateTime(doc['createdAt'])??DateTime.now(),
      updatedAt: _parseDateTime(doc['updatedAt'])??DateTime.now(),
      isActive: doc['isActive'] ?? true,
      currentStreak: doc['currentStreak'] ?? 0,
      longestStreak: doc['longestStreak'] ?? 0,
      totalCompletions: doc['totalCompletions'] ?? 0,
      lastCompletedAt: _parseDateTime(doc['lastCompletedAt']),
      customDays: _parseCustomDays(doc['customDays']),
      targetCount: doc['targetCount'] ?? 1,
    );
  }

  // Convert HabitModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category.name, // Convert enum to string
      'frequency': frequency.name, // Convert enum to string
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalCompletions': totalCompletions,
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      'customDays': customDays,
      'targetCount': targetCount,
    };
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category.name,
      'frequency': frequency.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalCompletions': totalCompletions,
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      'customDays': customDays,
      'targetCount': targetCount,
    };
  }

  // Create HabitModel from JSON
  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: _parseCategory(json['category']),
      frequency: _parseFrequency(json['frequency']),
      createdAt: _parseDateTime(json['createdAt'])??DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt'])??DateTime.now(),
      isActive: json['isActive'] ?? true,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalCompletions: json['totalCompletions'] ?? 0,
      lastCompletedAt: _parseDateTime(json['lastCompletedAt']),
      customDays: _parseCustomDays(json['customDays']),
      targetCount: json['targetCount'] ?? 1,
    );
  }

  // Create a copy with updated fields
  HabitModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    HabitCategory? category,
    HabitFrequency? frequency,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? currentStreak,
    int? longestStreak,
    int? totalCompletions,
    DateTime? lastCompletedAt,
    List<String>? customDays,
    int? targetCount,
  }) {
    return HabitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      customDays: customDays ?? this.customDays,
      targetCount: targetCount ?? this.targetCount,
    );
  }

  // Helper method to parse HabitCategory from string
  static HabitCategory _parseCategory(dynamic categoryValue) {
    if (categoryValue == null) return HabitCategory.personal;
    
    if (categoryValue is HabitCategory) return categoryValue;
    
    final categoryString = categoryValue.toString().toLowerCase();
    
    switch (categoryString) {
      case 'health':
        return HabitCategory.health;
      case 'productivity':
        return HabitCategory.productivity;
      case 'learning':
        return HabitCategory.learning;
      case 'social':
        return HabitCategory.social;
      case 'personal':
        return HabitCategory.personal;
      case 'finance':
        return HabitCategory.finance;
      default:
        return HabitCategory.personal;
    }
  }

  // Helper method to parse HabitFrequency from string
  static HabitFrequency _parseFrequency(dynamic frequencyValue) {
    if (frequencyValue == null) return HabitFrequency.daily;
    
    if (frequencyValue is HabitFrequency) return frequencyValue;
    
    final frequencyString = frequencyValue.toString().toLowerCase();
    
    switch (frequencyString) {
      case 'daily':
        return HabitFrequency.daily;
      case 'weekly':
        return HabitFrequency.weekly;
      case 'monthly':
        return HabitFrequency.monthly;
      case 'custom':
        return HabitFrequency.custom;
      default:
        return HabitFrequency.daily;
    }
  }

  // Helper method to parse custom days list
  static List<String> _parseCustomDays(dynamic customDaysValue) {
    if (customDaysValue == null) return [];
    
    if (customDaysValue is List) {
      return customDaysValue.map((day) => day.toString()).toList();
    }
    
    return [];
  }

  // Helper method to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    
    if (dateValue is DateTime) {
      return dateValue;
    }
    
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return null;
      }
    }
    
    // Handle Firestore Timestamp
    if (dateValue.runtimeType.toString().contains('Timestamp')) {
      return dateValue.toDate();
    }
    
    return null;
  }
}