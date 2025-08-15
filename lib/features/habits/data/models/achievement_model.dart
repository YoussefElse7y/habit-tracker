import '../../domain/entities/achievement.dart';

class AchievementModel extends Achievement {
  const AchievementModel({
    required super.id,
    required super.title,
    required super.description,
    required super.iconName,
    required super.type,
    required super.tier,
    required super.requirement,
    super.isUnlocked = false,
    super.unlockedAt,
    required super.points,
    super.category,
  });

  factory AchievementModel.fromFirestore(Map<String, dynamic> doc) {
    return AchievementModel(
      id: doc['id'] ?? '',
      title: doc['title'] ?? '',
      description: doc['description'] ?? '',
      iconName: doc['iconName'] ?? 'star',
      type: _parseAchievementType(doc['type']),
      tier: _parseAchievementTier(doc['tier']),
      requirement: doc['requirement'] ?? 0,
      isUnlocked: doc['isUnlocked'] ?? false,
      unlockedAt: _parseDateTime(doc['unlockedAt']),
      points: doc['points'] ?? 0,
      category: doc['category'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'type': type.name,
      'tier': tier.name,
      'requirement': requirement,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'points': points,
      'category': category,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'type': type.name,
      'tier': tier.name,
      'requirement': requirement,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'points': points,
      'category': category,
    };
  }

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconName: json['iconName'] ?? 'star',
      type: _parseAchievementType(json['type']),
      tier: _parseAchievementTier(json['tier']),
      requirement: json['requirement'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: _parseDateTime(json['unlockedAt']),
      points: json['points'] ?? 0,
      category: json['category'],
    );
  }

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    AchievementType? type,
    AchievementTier? tier,
    int? requirement,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? points,
    String? category,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      type: type ?? this.type,
      tier: tier ?? this.tier,
      requirement: requirement ?? this.requirement,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      points: points ?? this.points,
      category: category ?? this.category,
    );
  }

  static AchievementType _parseAchievementType(dynamic typeValue) {
    if (typeValue == null) return AchievementType.streak;
    if (typeValue is AchievementType) return typeValue;
    final typeString = typeValue.toString().toLowerCase();
    switch (typeString) {
      case 'streak':
        return AchievementType.streak;
      case 'completion':
        return AchievementType.completion;
      case 'milestone':
        return AchievementType.milestone;
      case 'special':
        return AchievementType.special;
      default:
        return AchievementType.streak;
    }
  }

  static AchievementTier _parseAchievementTier(dynamic tierValue) {
    if (tierValue == null) return AchievementTier.bronze;
    if (tierValue is AchievementTier) return tierValue;
    final tierString = tierValue.toString().toLowerCase();
    switch (tierString) {
      case 'bronze':
        return AchievementTier.bronze;
      case 'silver':
        return AchievementTier.silver;
      case 'gold':
        return AchievementTier.gold;
      case 'platinum':
        return AchievementTier.platinum;
      case 'diamond':
        return AchievementTier.diamond;
      default:
        return AchievementTier.bronze;
    }
  }

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
    if (dateValue.runtimeType.toString().contains('Timestamp')) {
      return dateValue.toDate();
    }
    return null;
  }
}
