import 'package:flutter/material.dart';
import 'package:taskbite/core/utils/routes_transitions.dart';
import 'package:taskbite/core/routes/routes.dart';
import 'package:taskbite/features/home/presentation/screens/home_screen.dart';
import 'package:taskbite/features/settings/presentation/screens/settings_screen.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/presentation/screens/task_details_screen.dart';
import '../../features/splash screen/presentation/screens/splash_screen.dart';

class AppRouter {
  static Route? onGenerateRoute(RouteSettings settings) {
    return CustomSlideNavigation(
      page: Builder(
        builder: (BuildContext context) {
          switch (settings.name) {
            case AppRoutes.splashScreen:
              return SplashScreen();
            case AppRoutes.homeScreen:
              return HomeScreen();
            case AppRoutes.settingsScreen:
              return SettingsScreen();
            case AppRoutes.taskDetailsScreen:
              Map<String, dynamic> args =
                  settings.arguments as Map<String, dynamic>;
              TaskModel task = args['task'];
              dynamic taskKey = args['taskKey'];
              return TaskDetailsScreen(task: task, taskKey: taskKey);
            default:
              return SplashScreen();
          }
        },
      ),
    );
  }
}
