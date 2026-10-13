import 'package:flutter/material.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_status_list.dart';

/// Dashboard tab: tasks that have not been started yet.
class NewTasksView extends StatelessWidget {
  const NewTasksView({super.key});

  @override
  Widget build(BuildContext context) =>
      const TaskStatusList(status: TaskStatus.newTask);
}
