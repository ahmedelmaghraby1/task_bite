import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskbite/core/helpers/hive_helper.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/tasks/presentation/widgets/no_tasks.dart';
import 'package:taskbite/features/home/presentation/widgets/head_title.dart';
import 'package:taskbite/features/home/presentation/widgets/search_bar.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_tile.dart';

class NewTasksView extends StatefulWidget {
  const NewTasksView({super.key});

  @override
  State<NewTasksView> createState() => _NewTasksViewState();
}

class _NewTasksViewState extends State<NewTasksView> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 3), () {
      setState(() {}); // إعادة بناء الواجهة لتحديث البحث
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(start: 20.w),
            child: HeadTitle(title: 'newTasks'.tr(context)),
          ),
          SizedBox(height: 20.h),
          SearchBox(
            textEditingController: _searchController,
            onChanged: _onSearchChanged,
          ),
          ValueListenableBuilder(
            valueListenable: HiveHelper.taskListenable(),
            builder: (context, Box<TaskModel> box, _) {
              var searchText = _searchController.text.toLowerCase();
              var tasks =
                  box
                      .toMap()
                      .entries
                      .where(
                        (entry) => entry.value.status == TaskStatus.newTask,
                      )
                      .where(
                        (entry) =>
                            searchText.isEmpty ||
                            entry.value.title.toLowerCase().contains(
                              searchText,
                            ) ||
                            entry.value.content.toLowerCase().contains(
                              searchText,
                            ),
                      )
                      .toList();

              return Expanded(
                child:
                    tasks.isEmpty
                        ? const NoTasks()
                        : ListView.separated(
                          padding: EdgeInsetsDirectional.only(
                            bottom: 20.h,
                            top: 20.h,
                            start: 15.w,
                            end: 15.w,
                          ),
                          separatorBuilder:
                              (context, index) => SizedBox(height: 15.h),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            var taskKey = tasks[index].key;
                            var task = tasks[index].value;
                            return TaskTile(task: task, taskKey: taskKey);
                          },
                        ),
              );
            },
          ),
        ],
      ),
    );
  }
}
