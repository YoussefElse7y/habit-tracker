// File: features/habits/presentation/widgets/achievement_card.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/achievement.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;
  final bool isUnlocked;
  final bool showProgress;
  final int? currentProgress;

  const AchievementCard({
    Key? key,
    required this.achievement,
    this.onTap,
    this.isUnlocked = false,
    this.showProgress = false,
    this.currentProgress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isUnlocked ? _getTierColor() : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isUnlocked 
                ? _getTierColor().withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and tier
                  Row(
                    children: [
                      // Achievement icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isUnlocked 
                            ? Colors.white.withOpacity(0.9)
                            : Colors.grey[400],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconData(),
                          size: 24,
                          color: isUnlocked 
                            ? _getTierColor()
                            : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Title and tier
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked 
                                  ? Colors.white
                                  : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isUnlocked 
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.grey[400],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                achievement.tier.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isUnlocked 
                                    ? Colors.white
                                    : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Points
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isUnlocked 
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey[400],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${achievement.points} pts',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked 
                              ? Colors.white
                              : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUnlocked 
                        ? Colors.white.withOpacity(0.9)
                        : Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Progress bar (if enabled)
                  if (showProgress && currentProgress != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (currentProgress! / achievement.requirement).clamp(0.0, 1.0),
                            backgroundColor: isUnlocked 
                              ? Colors.white.withOpacity(0.3)
                              : Colors.grey[400],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isUnlocked 
                                ? Colors.white
                                : Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$currentProgress/${achievement.requirement}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isUnlocked 
                              ? Colors.white.withOpacity(0.9)
                              : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Unlock date (if unlocked)
                  if (isUnlocked && achievement.unlockedAt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_open,
                          size: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Achievement type emoji (top right)
            Positioned(
              top: 12,
              right: 12,
              child: Text(
                achievement.typeEmoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            
            // Lock overlay (if not unlocked)
            if (!isUnlocked)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor() {
    switch (achievement.tier) {
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

  IconData _getIconData() {
    switch (achievement.iconName) {
      case 'flame':
        return Icons.local_fire_department;
      case 'check_circle':
        return Icons.check_circle;
      case 'star':
        return Icons.star;
      case 'trophy':
        return Icons.emoji_events;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'nightlight':
        return Icons.nightlight;
      case 'weekend':
        return Icons.weekend;
      case 'celebration':
        return Icons.celebration;
      case 'favorite':
        return Icons.favorite;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'people':
        return Icons.people;
      case 'person':
        return Icons.person;
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.star;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    }
  }
}