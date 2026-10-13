import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/domain/models/stored_task.dart';

/// Contract for every task persistence operation the UI needs.
///
/// Implementations are expected to be reactive: [watchTasks] re-emits the
/// current snapshot whenever any task is added, edited, deleted or changes
/// status. All mutation methods update [createdAt]/[updatedAt] appropriately.
abstract interface class TaskRepository {
  /// Stream of task snapshots. The first emission is the current state.
  Stream<List<StoredTask>> watchTasks();

  /// Returns the current snapshot (for one-shot reads).
  Future<List<StoredTask>> loadTasks();

  /// Applies the centralized overdue rule: every unfinished task whose due
  /// calendar day has passed becomes [TaskStatus.failed] and is persisted.
  /// Completed tasks and tasks without a due date are never touched, and
  /// already-failed tasks are never rewritten, so repeated calls are
  /// idempotent. Returns how many tasks changed status.
  Future<int> evaluateOverdue();

  Future<StoredTask> createTask({
    required String title,
    required String content,
    DateTime? dueDate,
  });

  Future<void> updateTask({
    required dynamic key,
    required String title,
    required String content,
    DateTime? dueDate,
  });

  Future<void> updateStatus({required dynamic key, required TaskStatus status});

  Future<void> deleteTask({required dynamic key});
}
