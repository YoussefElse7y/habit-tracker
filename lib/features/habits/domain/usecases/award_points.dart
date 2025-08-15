// File: features/habits/domain/usecases/award_points.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/achievement_repository.dart';

class AwardPoints implements UseCase<int, AwardPointsParams> {
  final AchievementRepository repository;

  AwardPoints(this.repository);

  @override
  Future<Either<Failure, int>> call(AwardPointsParams params) async {
    return await repository.awardPoints(
      params.userId,
      params.points,
      params.reason,
    );
  }
}

class AwardPointsParams {
  final String userId;
  final int points;
  final String reason;

  const AwardPointsParams({
    required this.userId,
    required this.points,
    required this.reason,
  });
}
