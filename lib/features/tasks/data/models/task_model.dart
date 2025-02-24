import 'package:hive/hive.dart';

part 'task_model.g.dart';

// Type Id (0) for tasks, (1) for Task status
@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String title;
  @HiveField(1)
  String content;
  @HiveField(2)
  TaskStatus status;

  TaskModel({
    required this.title,
    required this.content,
    this.status = TaskStatus.newTask,
  });
}

@HiveType(typeId: 1)
enum TaskStatus {
  @HiveField(0)
  newTask,
  @HiveField(1)
  pending,
  @HiveField(2)
  completed,
}
