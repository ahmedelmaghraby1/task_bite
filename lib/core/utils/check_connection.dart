import 'package:internet_connection_checker/internet_connection_checker.dart';

Future<bool> hasInternetConnection() async {
  final InternetConnectionChecker internetConnectionChecker;
  internetConnectionChecker = InternetConnectionChecker.instance;
  return await internetConnectionChecker.hasConnection;
}
