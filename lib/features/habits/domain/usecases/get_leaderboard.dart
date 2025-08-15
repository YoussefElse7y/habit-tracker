// File: features/habits/domain/usecases/get_leaderboard.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/achievement_repository.dart';

class GetLeaderboard implements UseCase<List<Map<String, dynamic>>, GetLeaderboardParams> {
  final AchievementRepository repository;

  GetLeaderboard(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(GetLeaderboardParams params) async {
    return await repository.getLeaderboard(
      category: params.category,
      limit: params.limit,
    );
  }
}

class GetLeaderboardParams {
  final String? category;
  final int limit;

  const GetLeaderboardParams({
    this.category,
    this.limit = 10,
  });
}