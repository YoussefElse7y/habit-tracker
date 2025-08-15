// File: core/constants/app_constants.dart

class AppConstants {
  // App Info
  static const String appName = 'Habit Tracker';
  static const String appVersion = '1.0.0';
  
  // Firebase Configuration (from your firebase_options.dart)
  static const String firebaseProjectId = 'habit-tracker-7b489';
  
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String habitsCollection = 'habits';
  static const String progressCollection = 'progress';
  static const String notificationsCollection = 'notifications';
  
  // Local Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String habitsKey = 'cached_habits';
  static const String settingsKey = 'app_settings';
  
  // Database
  static const String databaseName = 'habit_tracker.db';
  static const int databaseVersion = 1;
  
  // Habit Defaults
  static const int maxHabitsPerUser = 50;
  static const int defaultStreakGoal = 30;
  static const List<String> habitCategories = [
    'Health',
    'Productivity',
    'Learning',
    'Social',
    'Personal',
    'Finance'
  ];
  
  // Notification Settings
  static const String defaultNotificationTitle = 'Time for your habit!';
  static const String streakNotificationTitle = 'Streak Alert!';
  
  // Error Messages
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Please check your internet connection.';
  static const String authErrorMessage = 'Authentication failed. Please login again.';
  
  // Success Messages
  static const String habitAddedMessage = 'Habit added successfully!';
  static const String habitCompletedMessage = 'Great job! Keep the streak going!';
  static const String profileUpdatedMessage = 'Profile updated successfully!';

  static int pointsPerLevel;
}