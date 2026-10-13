import 'package:flutter/material.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_status_list.dart';

/// Dashboard tab: finished tasks (reopenable).
class CompletedTasksView extends StatelessWidget {
  const CompletedTasksView({super.key});

  @override
  Widget build(BuildContext context) =>
      const TaskStatusList(status: TaskStatus.completed);
}
