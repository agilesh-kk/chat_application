import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract class ConnectionChecker {
  Future<bool> get isConnected;
}

class ConnectionCheckerImpl implements ConnectionChecker {
  final InternetConnection _internetConnection;

  ConnectionCheckerImpl()
      : _internetConnection = InternetConnection();

  @override
  Future<bool> get isConnected => _internetConnection.hasInternetAccess;
}
