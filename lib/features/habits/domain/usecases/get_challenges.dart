// File: features/habits/domain/usecases/get_challenges.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/achievement_repository.dart';

class GetChallenges implements UseCase<List<Map<String, dynamic>>, GetChallengesParams> {
  final AchievementRepository repository;

  GetChallenges(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(GetChallengesParams params) async {
    return await repository.getChallenges(
      timeFrame: params.timeFrame,
      category: params.category,
    );
  }
}

class GetChallengesParams {
  final String? timeFrame;
  final String? category;

  const GetChallengesParams({
    this.timeFrame,
    this.category,
  });
}