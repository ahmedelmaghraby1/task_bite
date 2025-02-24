import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/presentation/widgets/delete_icon.dart';
import 'package:taskbite/features/tasks/presentation/widgets/done_icon.dart';
import 'package:taskbite/features/tasks/presentation/widgets/edit_icon.dart';
import 'package:taskbite/features/tasks/presentation/widgets/more_details.dart';
import 'package:taskbite/features/tasks/presentation/widgets/shadow_container.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_action_button.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_title.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  final dynamic taskKey;
  const TaskTile({super.key, required this.task, required this.taskKey});

  @override
  Widget build(BuildContext context) {
    return ShadowedContainer(
      borderColor: Theme.of(context).colorScheme.tertiary,
      padding: EdgeInsetsDirectional.only(
        start: 30.w,
        end: 15.w,
        top: 10.h,
        bottom: 10.h,
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5.h,
            children: [
              TaskTitle(title: task.title),
              MoreDetails(taskKey: taskKey, task: task),
            ],
          ),
          Spacer(),
          if (task.status == TaskStatus.newTask)
            Row(
              children: [
                TaskAction(taskKey: taskKey, status: task.status),
                SizedBox(width: 15.w),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    EditIcon(task: task, taskKey: taskKey),
                    SizedBox(height: 10.h),
                    DeleteIcon(task: task, taskKey: taskKey),
                  ],
                ),
              ],
            ),
          if (task.status == TaskStatus.pending)
            Row(
              children: [
                TaskAction(taskKey: taskKey, status: task.status),
                SizedBox(width: 15.w),
                DeleteIcon(task: task, taskKey: taskKey),
              ],
            ),
          if (task.status == TaskStatus.completed)
            Row(
              children: [
                DoneIcon(),
                SizedBox(width: 15.w),
                DeleteIcon(task: task, taskKey: taskKey),
              ],
            ),
        ],
      ),
    );
  }
}
