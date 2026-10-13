import 'package:flutter/material.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_status_list.dart';

/// Dashboard tab: unfinished tasks that missed their due date.
class FailedTasksView extends StatelessWidget {
  const FailedTasksView({super.key});

  @override
  Widget build(BuildContext context) =>
      const TaskStatusList(status: TaskStatus.failed);
}
