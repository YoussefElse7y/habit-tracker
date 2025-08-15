// File: features/habits/domain/usecases/get_all_achievements.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/achievement.dart';
import '../repositories/achievement_repository.dart';

class GetAllAchievements implements NoParamsUseCase<List<Achievement>> {
  final AchievementRepository repository;

  GetAllAchievements(this.repository);

  @override
  Future<Either<Failure, List<Achievement>>> call() async {
    return await repository.getAllAchievements();
  }
}