import 'package:hive/hive.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/domain/models/stored_task.dart';
import 'package:taskbite/features/tasks/domain/repositories/task_repository.dart';

/// Hive-backed [TaskRepository].
///
/// Hive remains the single source of local persistence. The box is opened
/// once during app startup (`HiveHelper.hiveInit`) and this repository only
/// reads and writes it. Legacy records stored before the `dueDate` /
/// `createdAt` / `updatedAt` fields existed are handled safely: unknown fields
/// deserialize as `null`.
class HiveTaskRepository implements TaskRepository {
  Box<TaskModel> get _box => Hive.box<TaskModel>('tasks');

  @override
  Stream<List<StoredTask>> watchTasks() {
    return _box.watch().map((event) => snapshot());
  }

  @override
  Future<List<StoredTask>> loadTasks() async => snapshot();

  @override
  Future<int> evaluateOverdue() async {
    final now = DateTime.now();
    var changed = 0;
    for (final task in _box.values) {
      if (!task.shouldBecomeFailed(now: now)) continue;
      task
        ..status = TaskStatus.failed
        ..markUpdated(at: now);
      await task.save();
      changed++;
    }
    return changed;
  }

  List<StoredTask> snapshot() {
    return _box
        .toMap()
        .entries
        .map((entry) => StoredTask(key: entry.key, task: entry.value))
        .toList(growable: false);
  }

  @override
  Future<StoredTask> createTask({
    required String title,
    required String content,
    DateTime? dueDate,
  }) async {
    final now = DateTime.now();
    final task = TaskModel(
      title: title.trim(),
      content: content.trim(),
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
    );
    final key = await _box.add(task);
    return StoredTask(key: key, task: task);
  }

  @override
  Future<void> updateTask({
    required dynamic key,
    required String title,
    required String content,
    DateTime? dueDate,
  }) async {
    final current = _box.get(key);
    if (current == null) return;
    current
      ..title = title.trim()
      ..content = content.trim();
    // Explicit null means clear
    current.dueDate = dueDate;
    current.markUpdated();
    await current.save();
  }

  @override
  Future<void> updateStatus({
    required dynamic key,
    required TaskStatus status,
  }) async {
    final current = _box.get(key);
    if (current == null) return;
    current
      ..status = status
      ..markUpdated();
    await current.save();
  }

  @override
  Future<void> deleteTask({required dynamic key}) async {
    await _box.delete(key);
  }
}
