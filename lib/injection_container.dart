import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'core/network/network_info.dart';

// Authentication feature
import 'features/authentication/data/datasources/auth_local_datasource.dart';
import 'features/authentication/data/datasources/auth_remote_datasource.dart';
import 'features/authentication/data/repositories/auth_repository_impl.dart';
import 'features/authentication/domain/repositories/auth_repository.dart';
import 'features/authentication/domain/usecases/login_user.dart';
import 'features/authentication/domain/usecases/register_user.dart';
import 'features/authentication/presentation/cubit/auth_cubit.dart';

// Habits feature
import 'features/habits/data/datasources/habit_local_datasource.dart';
import 'features/habits/data/datasources/habit_remote_datasource.dart';
import 'features/habits/data/repositories/habit_repository_impl.dart';
import 'features/habits/domain/repositories/habit_repository.dart';
import 'features/habits/domain/usecases/add_habit.dart';
import 'features/habits/domain/usecases/complete_habit.dart';
import 'features/habits/presentation/cubit/habit_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<InternetConnectionChecker>(() => InternetConnectionChecker());
  sl.registerLazySingleton<firebase_auth.FirebaseAuth>(() => firebase_auth.FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Data sources - Authentication
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(sharedPreferences: sl()));
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(
        firebaseAuth: sl(),
        firestore: sl(),
        googleSignIn: sl(),
      ));

  // Data sources - Habits
  sl.registerLazySingleton<HabitLocalDataSource>(() => HabitLocalDataSourceImpl(sharedPreferences: sl()));
  sl.registerLazySingleton<HabitRemoteDataSource>(() => HabitRemoteDataSourceImpl(firestore: sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));
  sl.registerLazySingleton<HabitRepository>(() => HabitRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));

  // Use cases - Authentication
  sl.registerLazySingleton<LoginUser>(() => LoginUser(sl()));
  sl.registerLazySingleton<RegisterUser>(() => RegisterUser(sl()));

  // Use cases - Habits
  sl.registerLazySingleton<AddHabit>(() => AddHabit(sl()));
  sl.registerLazySingleton<CompleteHabit>(() => CompleteHabit(sl()));

  // Cubits
  sl.registerFactory<AuthCubit>(() => AuthCubit(
        loginUser: sl(),
        registerUser: sl(),
        authRepository: sl(),
      ));
  sl.registerFactory<HabitCubit>(() => HabitCubit(
        addHabitUseCase: sl(),
        completeHabitUseCase: sl(),
        habitRepository: sl(),
      ));
}