import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskbite/core/helpers/hive_helper.dart';
import 'package:taskbite/core/localization/app_localization.dart';
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
                        spacing: 20.h,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomAppBar(task: task, taskKey: taskKey),

                          Text(
                            'taskTitle'.tr(context),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),

                          Text(
                            task.title,
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(fontWeight: FontWeight.w700),
                            textAlign: TextAlign.justify,
                          ),

                          Text(
                            'description'.tr(context),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),

                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Text(
                                    task.content,
                                    textAlign: TextAlign.justify,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'status'.tr(context),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  (task.status == TaskStatus.newTask
                                          ? 'new'
                                          : task.status == TaskStatus.pending
                                          ? 'pending'
                                          : 'completed')
                                      .tr(context),
                                  style: Theme.of(context).textTheme.bodyLarge!
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: AlignmentDirectional.center,
                            child:
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
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                        padding:
                                            EdgeInsetsDirectional.symmetric(
                                              horizontal: 4.w,
                                              vertical: 2.h,
                                            ),
                                        borderColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
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
                                        currentTask.status =
                                            TaskStatus.completed;
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
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                        padding:
                                            EdgeInsetsDirectional.symmetric(
                                              horizontal: 4.w,
                                              vertical: 2.h,
                                            ),
                                        borderColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        child: Center(
                                          child: Text(('complete').tr(context)),
                                        ),
                                      ),
                                    )
                                    : SizedBox(),
                          ),

                          SizedBox(height: 10.h),
                        ],
                      ),
                    )
                    : TaskNotFound(),
      ),
    );
  }
}
