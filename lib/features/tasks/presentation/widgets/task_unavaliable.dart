import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/localization/app_localization.dart';

class TaskNotFound extends StatelessWidget {
  const TaskNotFound({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10.h,
        children: [
          Text(
            'Task is deleted'.tr(context),
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
