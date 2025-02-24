import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskbite/core/helpers/hive_helper.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/home/presentation/widgets/head_title.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/presentation/widgets/custom_app_bar.dart';
import 'package:taskbite/features/tasks/presentation/widgets/shadow_container.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_unavaliable.dart';

class TaskDetailsScreen extends StatelessWidget {
  final TaskModel task;
  final dynamic taskKey;
  const TaskDetailsScreen({
    super.key,
    required this.task,
    required this.taskKey,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: HiveHelper.taskListenable(),
        builder:
            (context, Box<TaskModel> box, _) =>
                box.containsKey(taskKey)
                    ? Padding(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: 30.w,
                        vertical: 10.h,
                      ),
                      child: Column(
                        children: [
                          CustomAppBar(task: task, taskKey: taskKey),
                          Padding(
                            padding: EdgeInsetsDirectional.only(start: 15.w),
                            child: HeadTitle(title: 'taskContent'.tr(context)),
                          ),
                          SizedBox(height: 30.h),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.only(
                                      start: 15.w,
                                    ),
                                    child: Text(
                                      'taskTitle'.tr(context),
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Flexible(child: Text(task.title))],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.only(
                                  start: 15.w,
                                ),
                                child: Text(
                                  'description'.tr(context),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  SizedBox(height: 20.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(child: Text(task.content)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 20.h),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.only(
                                      start: 15.w,
                                    ),
                                    child: Text(
                                      'status'.tr(context),
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      (task.status == TaskStatus.newTask
                                              ? 'new'
                                              : task.status ==
                                                  TaskStatus.pending
                                              ? 'pending'
                                              : 'completed')
                                          .tr(context),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20.h),
                              task.status == TaskStatus.newTask
                                  ? GestureDetector(
                                    onTap: () {
                                      Box tasksBox = Hive.box<TaskModel>(
                                        'tasks',
                                      );
                                      TaskModel currentTask = tasksBox.get(
                                        taskKey,
                                      );
                                      currentTask.status = TaskStatus.pending;
                                      currentTask.save();
                                    },
                                    child: ShadowedContainer(
                                      width: 90.w,
                                      height: 34.h,
                                      borderWidth: 0,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.inversePrimary,
                                      borderRadius: BorderRadius.circular(10.r),
                                      padding: EdgeInsetsDirectional.symmetric(
                                        horizontal: 4.w,
                                        vertical: 2.h,
                                      ),
                                      borderColor:
                                          Theme.of(context).colorScheme.primary,
                                      child: Center(
                                        child: Text(('start').tr(context)),
                                      ),
                                    ),
                                  )
                                  : task.status == TaskStatus.pending
                                  ? GestureDetector(
                                    onTap: () {
                                      Box tasksBox = Hive.box<TaskModel>(
                                        'tasks',
                                      );
                                      TaskModel currentTask = tasksBox.get(
                                        taskKey,
                                      );
                                      currentTask.status = TaskStatus.completed;
                                      currentTask.save();
                                    },
                                    child: ShadowedContainer(
                                      width: 90.w,
                                      height: 34.h,
                                      borderWidth: 0,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.inversePrimary,
                                      borderRadius: BorderRadius.circular(10.r),
                                      padding: EdgeInsetsDirectional.symmetric(
                                        horizontal: 4.w,
                                        vertical: 2.h,
                                      ),
                                      borderColor:
                                          Theme.of(context).colorScheme.primary,
                                      child: Center(
                                        child: Text(('complete').tr(context)),
                                      ),
                                    ),
                                  )
                                  : SizedBox(),
                              SizedBox(height: 10.h),
                            ],
                          ),
                        ],
                      ),
                    )
                    : TaskNotFound(),
      ),
    );
  }
}
