import 'package:flutter/foundation.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/domain/models/stored_task.dart';

/// State for the task dashboard and the status views.
///
/// Holds the live snapshot of persisted tasks plus the shared search query.
/// Counts and filtered lists are derived getters, so they always reflect the
/// real persisted data and stay testable without a widget tree.
@immutable
class TasksState {
  const TasksState({
    this.tasks = const <StoredTask>[],
    this.searchQuery = '',
    this.isLoading = true,
    this.errorMessage,
  });

  final List<StoredTask> tasks;
  final String searchQuery;
  final bool isLoading;

  /// Localization key for a load error, when the stream failed.
  final String? errorMessage;

  bool get hasQuery => searchQuery.trim().isNotEmpty;

  int get totalCount => tasks.length;
  int get newCount =>
      tasks.where((t) => t.task.status == TaskStatus.newTask).length;
  int get pendingCount =>
      tasks.where((t) => t.task.status == TaskStatus.pending).length;
  int get completedCount =>
      tasks.where((t) => t.task.status == TaskStatus.completed).length;
  int get failedCount =>
      tasks.where((t) => t.task.status == TaskStatus.failed).length;

  /// Tasks that have not been completed yet.
  int get activeCount => newCount + pendingCount;

  double get completionRatio =>
      totalCount == 0 ? 0 : completedCount / totalCount;

  List<StoredTask> byStatus(TaskStatus status) {
    return _filter(tasks.where((t) => t.task.status == status));
  }

  List<StoredTask> searchAll({TaskStatus? status}) {
    final source =
        status == null ? tasks : tasks.where((t) => t.task.status == status);
    return _filter(source);
  }

  List<StoredTask> _filter(Iterable<StoredTask> source) {
    final query = searchQuery.trim().toLowerCase();
    final result = source
        .where((entry) {
          if (query.isEmpty) return true;
          return entry.task.title.toLowerCase().contains(query) ||
              entry.task.content.toLowerCase().contains(query);
        })
        .toList(growable: false);
    return result;
  }

  TasksState copyWith({
    List<StoredTask>? tasks,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
