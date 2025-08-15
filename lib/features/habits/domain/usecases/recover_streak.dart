// File: features/habits/domain/usecases/recover_streak.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/achievement_repository.dart';

class RecoverStreak implements UseCase<bool, RecoverStreakParams> {
  final AchievementRepository repository;

  RecoverStreak(this.repository);

  @override
  Future<Either<Failure, bool>> call(RecoverStreakParams params) async {
    return await repository.useStreakRecovery(
      params.userId,
      params.habitId,
    );
  }
}

class RecoverStreakParams {
  final String userId;
  final String habitId;

  const RecoverStreakParams({
    required this.userId,
    required this.habitId,
  });
}