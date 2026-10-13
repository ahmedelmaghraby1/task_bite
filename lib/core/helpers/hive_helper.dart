import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskbite/core/utils/alert_dialog.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/domain/models/stored_task.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_composer_sheet.dart';
import 'package:flutter/material.dart';

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
    showTaskComposer(context, existing: StoredTask(key: taskKey, task: task));
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
