import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habit_tracker_app/features/authentication/presentation/pages/auth_wrapper.dart';
import 'package:habit_tracker_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:habit_tracker_app/features/habits/presentation/cubit/habit_cubit.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await di.init();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthCubit>(),
        ),
        BlocProvider(
          create: (_) => di.sl<HabitCubit>(),
        ),
      ],
      child: const MaterialApp(
        title: 'Habit Tracker',
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(),
      ),
    );
  }
}
