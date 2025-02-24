import 'package:flutter/material.dart';
import 'package:taskbite/core/helpers/hive_helper.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';

class EditIcon extends StatelessWidget {
  final TaskModel task;
  final dynamic taskKey;
  const EditIcon({super.key, required this.task, required this.taskKey});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HiveHelper.editTask(context: context, taskKey: taskKey, task: task);
      },
      child: CircleAvatar(child: Icon(Icons.edit)),
    );
  }
}
