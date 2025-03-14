import 'dart:developer';

import 'package:internet_connection_checker/internet_connection_checker.dart';

Future<bool> hasInternetConnection() async {
  final InternetConnectionChecker internetConnectionChecker;
  internetConnectionChecker = InternetConnectionChecker.createInstance(
    checkTimeout: const Duration(seconds: 1), // Reduce timeout to 2 seconds
    checkInterval: const Duration(seconds: 1),
  );
  final bool hasConnection = await internetConnectionChecker.hasConnection;
  log(hasConnection.toString());
  return hasConnection;
}
