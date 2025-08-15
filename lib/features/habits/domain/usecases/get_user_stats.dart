// File: features/habits/domain/usecases/get_user_stats.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_stats.dart';
import '../repositories/achievement_repository.dart';

class GetUserStats implements UseCase<UserStats, GetUserStatsParams> {
  final AchievementRepository repository;

  GetUserStats(this.repository);

  @override
  Future<Either<Failure, UserStats>> call(GetUserStatsParams params) async {
    return await repository.getUserStats(params.userId);
  }
}

class GetUserStatsParams {
  final String userId;

  const GetUserStatsParams({
    required this.userId,
  });
}