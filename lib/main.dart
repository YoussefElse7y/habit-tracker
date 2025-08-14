import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:habit_tracker_app/features/authentication/presentation/pages/auth_wrapper.dart';
import 'firebase_options.dart';



void main() async {
    WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
//  await di.init();

  runApp( const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      

      home: AuthWrapper(),
    );
  }
}
