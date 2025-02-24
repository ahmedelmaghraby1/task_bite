import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskbite/core/helpers/app_bloc_observer.dart';
import 'package:taskbite/core/helpers/hive_helper.dart';
import 'package:taskbite/core/injection/injection.dart';

Future<void> appInit() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveHelper.hiveInit();
  initGetIt();
  Bloc.observer = AppBlocObserver();
}
