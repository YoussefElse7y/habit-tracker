// File: features/habits/domain/entities/challenge.dart

import 'package:equatable/equatable.dart';

enum ChallengeType {
  daily,      // Daily challenges
  weekly,     // Weekly challenges
  monthly,    // Monthly challenges
  special,    // Special event challenges
  seasonal,   // Seasonal challenges
}

enum ChallengeStatus {
  active,     // Challenge is currently active
  completed,  // Challenge has been completed
  expired,    // Challenge has expired
  upcoming,   // Challenge is upcoming
}

class Challenge extends Equatable {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final int pointsReward;
  final List<String> requirements; // List of requirement IDs or descriptions
  final Map<String, dynamic> criteria; // Specific criteria for completion
  final int maxParticipants; // 0 means unlimited
  final int currentParticipants;
  final String? category;
  final String? iconName;
  final bool isRepeatable;
  final int repeatCooldownDays; // Days before challenge can be repeated

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.pointsReward,
    required this.requirements,
    required this.criteria,
    this.maxParticipants = 0,
    this.currentParticipants = 0,
    this.category,
    this.iconName,
    this.isRepeatable = false,
    this.repeatCooldownDays = 0,
  });

  // Create a copy with updated fields
  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    ChallengeStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? pointsReward,
    List<String>? requirements,
    Map<String, dynamic>? criteria,
    int? maxParticipants,
    int? currentParticipants,
    String? category,
    String? iconName,
    bool? isRepeatable,
    int? repeatCooldownDays,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pointsReward: pointsReward ?? this.pointsReward,
      requirements: requirements ?? this.requirements,
      criteria: criteria ?? this.criteria,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      isRepeatable: isRepeatable ?? this.isRepeatable,
      repeatCooldownDays: repeatCooldownDays ?? this.repeatCooldownDays,
    );
  }

  // Check if challenge is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate) && status == ChallengeStatus.active;
  }

  // Check if challenge is expired
  bool get isExpired => DateTime.now().isAfter(endDate);

  // Check if challenge is upcoming
  bool get isUpcoming => DateTime.now().isBefore(startDate);

  // Get time remaining until challenge starts
  Duration? get timeUntilStart {
    if (isUpcoming) {
      return startDate.difference(DateTime.now());
    }
    return null;
  }

  // Get time remaining until challenge ends
  Duration? get timeUntilEnd {
    if (isActive) {
      return endDate.difference(DateTime.now());
    }
    return null;
  }

  // Get challenge duration
  Duration get duration => endDate.difference(startDate);

  // Check if challenge can accept more participants
  bool get canJoin => maxParticipants == 0 || currentParticipants < maxParticipants;

  // Get participation percentage
  double get participationPercentage {
    if (maxParticipants == 0) return 0.0;
    return (currentParticipants / maxParticipants).clamp(0.0, 1.0);
  }

  // Get challenge type emoji
  String get typeEmoji {
    switch (type) {
      case ChallengeType.daily:
        return '📅';
      case ChallengeType.weekly:
        return '📆';
      case ChallengeType.monthly:
        return '🗓️';
      case ChallengeType.special:
        return '🎯';
      case ChallengeType.seasonal:
        return '🍂';
    }
  }

  // Get status emoji
  String get statusEmoji {
    switch (status) {
      case ChallengeStatus.active:
        return '🟢';
      case ChallengeStatus.completed:
        return '✅';
      case ChallengeStatus.expired:
        return '🔴';
      case ChallengeStatus.upcoming:
        return '🟡';
    }
  }

  // Get formatted time remaining
  String get timeRemainingText {
    if (isExpired) return 'Expired';
    if (isUpcoming) {
      final duration = timeUntilStart!;
      if (duration.inDays > 0) return 'Starts in ${duration.inDays} days';
      if (duration.inHours > 0) return 'Starts in ${duration.inHours} hours';
      return 'Starts soon';
    }
    if (isActive) {
      final duration = timeUntilEnd!;
      if (duration.inDays > 0) return '${duration.inDays} days left';
      if (duration.inHours > 0) return '${duration.inHours} hours left';
      return 'Ends soon';
    }
    return 'Unknown';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        status,
        startDate,
        endDate,
        pointsReward,
        requirements,
        criteria,
        maxParticipants,
        currentParticipants,
        category,
        iconName,
        isRepeatable,
        repeatCooldownDays,
      ];
}