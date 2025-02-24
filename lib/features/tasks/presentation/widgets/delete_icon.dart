import 'package:flutter/material.dart';
import 'package:taskbite/core/helpers/hive_helper.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';

class DeleteIcon extends StatelessWidget {
  final TaskModel task;
  final dynamic taskKey;
  const DeleteIcon({super.key, required this.task, required this.taskKey});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HiveHelper.deleteTask(context: context, taskKey: taskKey);
      },
      child: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.error,
        child: Icon(Icons.delete_outline),
      ),
    );
  }
}
