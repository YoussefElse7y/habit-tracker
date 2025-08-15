// File: features/habits/domain/usecases/check_achievements.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/achievement.dart';
import '../repositories/achievement_repository.dart';

class CheckAchievements implements UseCase<List<Achievement>, CheckAchievementsParams> {
  final AchievementRepository repository;

  CheckAchievements(this.repository);

  @override
  Future<Either<Failure, List<Achievement>>> call(CheckAchievementsParams params) async {
    return await repository.checkAndUnlockAchievements(
      params.userId,
      params.progressData,
    );
  }
}

class CheckAchievementsParams {
  final String userId;
  final Map<String, dynamic> progressData;

  const CheckAchievementsParams({
    required this.userId,
    required this.progressData,
  });
}