import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/helpers/hive_helper.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/presentation/widgets/shadow_container.dart';

class TaskAction extends StatelessWidget {
  final dynamic taskKey;
  final TaskStatus status;
  const TaskAction({super.key, required this.taskKey, required this.status});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HiveHelper.updateTaskStatus(
          status == TaskStatus.newTask
              ? TaskStatus.pending
              : TaskStatus.completed,
          taskKey,
        );
      },
      child: ShadowedContainer(
        width: 90.w,
        height: 34.h,
        borderWidth: 0,
        color: Theme.of(context).colorScheme.inversePrimary,
        borderRadius: BorderRadius.circular(10.r),
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: 4.w,
          vertical: 2.h,
        ),
        borderColor: Theme.of(context).colorScheme.primary,
        child: Center(
          child: Text(
            (status == TaskStatus.newTask
                    ? 'start'
                    : status == TaskStatus.pending
                    ? 'complete'
                    : '')
                .tr(context),
          ),
        ),
      ),
    );
  }
}
