import 'package:flutter/material.dart';
import 'package:taskbite/core/source/app.dart' show TaskBite;
import 'package:taskbite/core/source/app_initiallization.dart' show appInit;

Future<void> main() async {
  await appInit();
  runApp(const TaskBite());
}
