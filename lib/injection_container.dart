import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'core/network/network_info.dart';

// Authentication
import 'features/authentication/data/datasources/auth_remote_datasource.dart';
import 'features/authentication/data/datasources/auth_local_datasource.dart';
import 'features/authentication/data/repositories/auth_repository_impl.dart';
import 'features/authentication/domain/repositories/auth_repository.dart';
import 'features/authentication/domain/usecases/login_user.dart';
import 'features/authentication/domain/usecases/register_user.dart';
import 'features/authentication/domain/usecases/get_current_user.dart';
import 'features/authentication/domain/usecases/logout_user.dart';
import 'features/authentication/domain/usecases/send_password_reset_email.dart';
import 'features/authentication/domain/usecases/update_profile.dart';
import 'features/authentication/presentation/cubit/auth_cubit.dart';

// Habits
import 'features/habits/data/datasources/habit_remote_datasource.dart';
import 'features/habits/data/datasources/habit_local_datasource.dart';
import 'features/habits/data/repositories/habit_repository_impl.dart';
import 'features/habits/domain/repositories/habit_repository.dart';
import 'features/habits/domain/usecases/add_habit.dart';
import 'features/habits/domain/usecases/complete_habit.dart';
import 'features/habits/presentation/cubit/habit_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // External
  final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  sl.registerLazySingleton<InternetConnectionChecker>(() => InternetConnectionChecker());

  sl.registerLazySingleton<firebase_auth.FirebaseAuth>(() => firebase_auth.FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Data sources - Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(
        firebaseAuth: sl<firebase_auth.FirebaseAuth>(),
        firestore: sl<FirebaseFirestore>(),
        googleSignIn: sl<GoogleSignIn>(),
      ));
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(
        sharedPreferences: sl<SharedPreferences>(),
      ));

  // Data sources - Habits
  sl.registerLazySingleton<HabitRemoteDataSource>(() => HabitRemoteDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
      ));
  sl.registerLazySingleton<HabitLocalDataSource>(() => HabitLocalDataSourceImpl(
        sharedPreferences: sl<SharedPreferences>(),
      ));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl<AuthRemoteDataSource>(),
        localDataSource: sl<AuthLocalDataSource>(),
        networkInfo: sl<NetworkInfo>(),
      ));

  sl.registerLazySingleton<HabitRepository>(() => HabitRepositoryImpl(
        remoteDataSource: sl<HabitRemoteDataSource>(),
        localDataSource: sl<HabitLocalDataSource>(),
        networkInfo: sl<NetworkInfo>(),
      ));

  // Use cases - Auth
  sl.registerLazySingleton(() => LoginUser(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUser(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUser(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUser(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SendPasswordResetEmail(sl<AuthRepository>()));
  sl.registerLazySingleton(() => UpdateProfile(sl<AuthRepository>()));

  // Use cases - Habits
  sl.registerLazySingleton(() => AddHabit(sl<HabitRepository>()));
  sl.registerLazySingleton(() => CompleteHabit(sl<HabitRepository>()));

  // Cubits
  sl.registerFactory(() => AuthCubit(
        loginUser: sl<LoginUser>(),
        registerUser: sl<RegisterUser>(),
        authRepository: sl<AuthRepository>(),
      ));

  sl.registerFactory(() => HabitCubit(
        addHabitUseCase: sl<AddHabit>(),
        completeHabitUseCase: sl<CompleteHabit>(),
        habitRepository: sl<HabitRepository>(),
      ));
}