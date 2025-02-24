import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/core/routes/routes.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';

class MoreDetails extends StatelessWidget {
  const MoreDetails({super.key, required this.taskKey, required this.task});

  final dynamic taskKey;
  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 15.w),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.taskDetailsScreen,
            arguments: {'taskKey': taskKey, 'task': task},
          );
        },
        child: Text('moreDetails'.tr(context)),
      ),
    );
  }
}
