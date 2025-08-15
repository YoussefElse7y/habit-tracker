import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core
import 'core/network/network_info.dart';

// Authentication Feature
import 'features/authentication/data/datasources/auth_local_datasource.dart';
import 'features/authentication/data/datasources/auth_remote_datasource.dart';
import 'features/authentication/data/repositories/auth_repository_impl.dart';
import 'features/authentication/domain/repositories/auth_repository.dart';
import 'features/authentication/domain/usecases/get_current_user.dart';
import 'features/authentication/domain/usecases/login_user.dart';
import 'features/authentication/domain/usecases/logout_user.dart';
import 'features/authentication/domain/usecases/register_user.dart';
import 'features/authentication/domain/usecases/send_password_reset_email.dart';
import 'features/authentication/domain/usecases/update_profile.dart';
import 'features/authentication/presentation/cubit/auth_cubit.dart';

// Habits Feature
import 'features/habits/data/datasources/habit_local_datasource.dart';
import 'features/habits/data/datasources/habit_remote_datasource.dart';
import 'features/habits/data/repositories/habit_repository_impl.dart';
import 'features/habits/domain/repositories/habit_repository.dart';
import 'features/habits/domain/usecases/add_habit.dart';
import 'features/habits/domain/usecases/complete_habit.dart';
import 'features/habits/presentation/cubit/habit_cubit.dart';

  // Achievement Feature
  import 'features/habits/data/datasources/achievement_local_datasource.dart';
  import 'features/habits/data/datasources/achievement_remote_datasource.dart';
  import 'features/habits/data/repositories/achievement_repository_impl.dart';
  import 'features/habits/domain/repositories/achievement_repository.dart';
  import 'features/habits/domain/usecases/check_achievements.dart';
  import 'features/habits/domain/usecases/get_user_stats.dart';
  import 'features/habits/domain/usecases/award_points.dart';
  import 'features/habits/domain/usecases/get_all_achievements.dart';
  import 'features/habits/domain/usecases/get_achievement_progress.dart';
  import 'features/habits/domain/usecases/get_challenges.dart';
  import 'features/habits/domain/usecases/get_leaderboard.dart';
  import 'features/habits/domain/usecases/recover_streak.dart';
  import 'features/habits/presentation/cubit/achievement_cubit.dart';

// Profile Feature
import 'features/profile/presentation/cubit/profile_cubit.dart';

// Goals Feature
import 'features/goals/presentation/cubit/goals_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerFactory(
    () => AuthCubit(
      loginUser: sl(),
      registerUser: sl(),
      authRepository: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => LogoutUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerLazySingleton(() => SendPasswordResetEmail(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
      googleSignIn: sl(),
    ),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );


  sl.registerFactory(
    () => HabitCubit(
      addHabitUseCase: sl(),
      completeHabitUseCase: sl(),
      habitRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => ProfileCubit(
      firebaseAuth: sl(),
      firestore: sl(),
      storage: sl(),
      imagePicker: sl(),
    ),
  );

  sl.registerFactory(
    () => GoalsCubit(
      firebaseAuth: sl(),
      firestore: sl(),
    ),
  );

  // Achievement System
  sl.registerFactory(
    () => AchievementCubit(
      achievementRepository: sl(),
      checkAchievements: sl(),
      getUserStats: sl(),
    ),
  );

  sl.registerLazySingleton(() => CheckAchievements(sl()));
  sl.registerLazySingleton(() => GetUserStats(sl()));
  sl.registerLazySingleton(() => AwardPoints(sl()));
  sl.registerLazySingleton(() => GetAllAchievements(sl()));
  sl.registerLazySingleton(() => GetAchievementProgress(sl()));
  sl.registerLazySingleton(() => GetChallenges(sl()));
  sl.registerLazySingleton(() => GetLeaderboard(sl()));
  sl.registerLazySingleton(() => RecoverStreak(sl()));

  sl.registerLazySingleton<AchievementRepository>(
    () => AchievementRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<AchievementRemoteDataSource>(
    () => AchievementRemoteDataSourceImpl(
      firestore: sl(),
    ),
  );

  sl.registerLazySingleton<AchievementLocalDataSource>(
    () => AchievementLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );


  sl.registerLazySingleton(() => AddHabit(sl()));
  sl.registerLazySingleton(() => CompleteHabit(sl()));

  sl.registerLazySingleton<HabitRepository>(
    () => HabitRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      getCurrentUser: sl(),
    ),
  );

  sl.registerLazySingleton<HabitRemoteDataSource>(
    () => HabitRemoteDataSourceImpl(
      firestore: sl(),
    ),
  );

  sl.registerLazySingleton<HabitLocalDataSource>(
    () => HabitLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );

  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => GoogleSignIn.instance);
  sl.registerLazySingleton(() => ImagePicker());
  sl.registerLazySingleton(() => InternetConnectionChecker.instance);
}