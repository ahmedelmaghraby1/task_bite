import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskbite/core/utils/alert_dialog.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:taskbite/features/tasks/presentation/widgets/custom_modal_bottom_sheet.dart';

class HiveHelper {
  static Future<void> hiveInit() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(TaskModelAdapter().typeId)) {
      Hive.registerAdapter(TaskModelAdapter());
    }
    if (!Hive.isAdapterRegistered(TaskStatusAdapter().typeId)) {
      Hive.registerAdapter(TaskStatusAdapter());
    }

    await Future.wait([
      Hive.openBox<TaskModel>('tasks'),
      Hive.openBox<dynamic>('settings'),
    ]);
  }

  static void editTask({
    required BuildContext context,
    required dynamic taskKey,
    required TaskModel task,
  }) {
    showModalBottomSheet(
      isScrollControlled: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (context) => CustomModalBottomSheet(),
    );
  }

  static void deleteTask({
    required BuildContext context,
    required dynamic taskKey,
  }) {
    showAlertDialog(
      context,
      message: 'deletingMessage',
      yesTitle: 'yes',
      noTitle: 'no',
      onYesFunction: () {
        Box tasksBox = Hive.box<TaskModel>('tasks');
        tasksBox.delete(taskKey);
        Navigator.pop(context);
      },
      onNoFunction: () {
        Navigator.pop(context);
      },
    );
  }

  static updateTaskStatus(TaskStatus status, dynamic taskKey) {
    Box tasksBox = Hive.box<TaskModel>('tasks');
    TaskModel currentTask = tasksBox.get(taskKey);
    currentTask.status = status;
    currentTask.save();
  }

  static ValueListenable<Box<TaskModel>> taskListenable() {
    return Hive.box<TaskModel>('tasks').listenable();
  }

  static ValueListenable<Box<dynamic>> settingsListenable() {
    return Hive.box<dynamic>('settings').listenable();
  }
}
