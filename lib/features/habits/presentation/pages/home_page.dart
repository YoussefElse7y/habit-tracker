import 'package:flutter/material.dart';
import 'package:habit_tracker_app/features/authentication/domain/entities/user.dart';

class HomePage extends StatelessWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, TO HOME PAGE'),
      ),
      body: Center(
        child: Text('This is the home page.'),
      ),
    );
  }
}