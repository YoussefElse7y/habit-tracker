
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Abstract class for checking network connectivity
/// This allows for easy testing and dependency injection
abstract class NetworkInfo {
  /// Check if the device is connected to the internet
  Future<bool> get isConnected;
}

/// Implementation of NetworkInfo using internet_connection_checker
class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}