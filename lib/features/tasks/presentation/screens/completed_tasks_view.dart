import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskbite/core/helpers/hive_helper.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_tile.dart';
import 'package:taskbite/features/tasks/presentation/widgets/no_tasks.dart';
import 'package:taskbite/features/home/presentation/widgets/head_title.dart';
import 'package:taskbite/features/home/presentation/widgets/search_bar.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';

class CompletedTasksView extends StatefulWidget {
  const CompletedTasksView({super.key});

  @override
  State<CompletedTasksView> createState() => _CompletedTasksViewState();
}

class _CompletedTasksViewState extends State<CompletedTasksView> {
  late final TextEditingController _searchController;

  Timer? _debounce; // تايمر لتأخير البحث
  List filteredTasks = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _filterTasks(); // تشغيل البحث أول مرة عشان يعرض كل التاسكات
  }

  void _filterTasks() {
    var box = Hive.box<TaskModel>('tasks');
    var searchText = _searchController.text.toLowerCase();

    setState(() {
      filteredTasks =
          box.values
              .where(
                (task) =>
                    task.title.toLowerCase().contains(searchText) ||
                    task.content.toLowerCase().contains(searchText),
              )
              .toList();
    });
  }

  void _onSearchChanged(String value) {
    // لو التايمر شغال، الغيه قبل ما تبدأ تايمر جديد
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // تشغيل التايمر، وبعد 3 ثواني يتم استدعاء `setState()`
    _debounce = Timer(Duration(seconds: 3), () {
      _filterTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel(); // إلغاء التايمر عند الخروج من الصفحة
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(start: 20.w),
            child: HeadTitle(title: 'completedTasks'.tr(context)),
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
                        (entry) => entry.value.status == TaskStatus.completed,
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
