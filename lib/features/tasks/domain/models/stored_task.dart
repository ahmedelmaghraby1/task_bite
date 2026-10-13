import 'package:taskbite/features/tasks/data/models/task_model.dart';

/// A task together with the Hive key it is stored under. Keeping the key and
/// the value paired is required because every task mutation (edit, status
/// change, delete) is keyed, not value-keyed.
class StoredTask {
  const StoredTask({required this.key, required this.task});

  final dynamic key;
  final TaskModel task;

  @override
  String toString() => 'StoredTask(key: $key, task: ${task.toString()})';
}
