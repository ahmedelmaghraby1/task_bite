import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/home/presentation/widgets/head_title.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/presentation/widgets/back_icon.dart';
import 'package:taskbite/features/tasks/presentation/widgets/delete_icon.dart';
import 'package:taskbite/features/tasks/presentation/widgets/edit_icon.dart';

class CustomAppBar extends StatelessWidget {
  final TaskModel task;
  final dynamic taskKey;
  const CustomAppBar({super.key, required this.task, required this.taskKey});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 50.h),

        Row(
          children: [
            BackIcon(),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 15.w),
              child: HeadTitle(title: 'taskContent'.tr(context)),
            ),
            Spacer(),
            if (task.status == TaskStatus.newTask)
              EditIcon(task: task, taskKey: taskKey),
            SizedBox(width: 15.h),
            DeleteIcon(task: task, taskKey: taskKey),
          ],
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}
