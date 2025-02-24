import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskbite/core/constants/enums.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/core/themes/colors.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';

class AddTaskButton extends StatelessWidget {
  final ModalType type;
  final TaskModel? task;
  final bool titleEmpty;
  final dynamic taskKey;
  final GlobalKey<FormState> taskFormKey;
  final TextEditingController titleController;
  final TextEditingController contentController;
  const AddTaskButton({
    super.key,
    required this.titleController,
    required this.taskFormKey,
    required this.contentController,
    required this.titleEmpty,
    required this.type,
    this.taskKey,
    this.task,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (taskFormKey.currentState!.validate()) {
          Box taskBox = Hive.box<TaskModel>('tasks');
          switch (type) {
            case ModalType.edit:
              task?.title = titleController.text;
              task?.content = contentController.text;
              task?.save();

            case ModalType.create:
              TaskModel newTask = TaskModel(
                title: titleController.text,
                content: contentController.text,
              );
              taskBox.add(newTask);
          }
          Navigator.pop(context);
        }
      },
      child: AnimatedContainer(
        height: 60.h,
        width: 350.w,
        duration: const Duration(milliseconds: 300),
        curve: Curves.bounceInOut,
        decoration: BoxDecoration(
          color: titleEmpty ? AppColors.grey : AppColors.white,
          gradient:
              titleEmpty
                  ? null
                  : LinearGradient(
                    colors: [AppColors.purpple, AppColors.lightPurpple],
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                  ),
          borderRadius: BorderRadius.circular(50.r),
        ),
        child: Center(
          child: Text(
            (type == ModalType.create ? 'add' : 'update').tr(context),
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
