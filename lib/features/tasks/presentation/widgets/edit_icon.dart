import 'package:flutter/material.dart';
import 'package:taskbite/core/helpers/hive_helper.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/presentation/widgets/custom_circle_avatar.dart';

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
      child: CustomCircleAvatar(child: Icon(Icons.edit, size: 20)),
    );
  }
}
