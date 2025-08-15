// File: features/habits/domain/usecases/get_achievement_progress.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/achievement.dart';
import '../repositories/achievement_repository.dart';

class GetAchievementProgress implements UseCase<Map<String, int>, GetAchievementProgressParams> {
  final AchievementRepository repository;

  GetAchievementProgress(this.repository);

  @override
  Future<Either<Failure, Map<String, int>>> call(GetAchievementProgressParams params) async {
    return await repository.getAchievementProgress(
      params.userId,
      params.achievements,
    );
  }
}

class GetAchievementProgressParams {
  final String userId;
  final List<Achievement> achievements;

  const GetAchievementProgressParams({
    required this.userId,
    required this.achievements,
  });
}
