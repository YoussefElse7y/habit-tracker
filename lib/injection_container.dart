import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Authentication
  // Cubit
  sl.registerFactory(
    () => AuthCubit(
      loginUser: sl(),
      registerUser: sl(),
      authRepository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => LogoutUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerLazySingleton(() => SendPasswordResetEmail(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
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

  //! Features - Habits
  // Cubit
  sl.registerFactory(
    () => HabitCubit(
      addHabitUseCase: sl(),
      completeHabitUseCase: sl(),
      habitRepository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => AddHabit(sl()));
  sl.registerLazySingleton(() => CompleteHabit(sl()));

  // Repository
  sl.registerLazySingleton<HabitRepository>(
    () => HabitRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<HabitRemoteDataSource>(
    () => HabitRemoteDataSourceImpl(
      firestore: sl(),
      firebaseAuth: sl(),
    ),
  );

  sl.registerLazySingleton<HabitLocalDataSource>(
    () => HabitLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
  sl.registerLazySingleton(() => InternetConnectionChecker());
}