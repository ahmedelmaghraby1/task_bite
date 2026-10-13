import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/domain/models/stored_task.dart';
import 'package:taskbite/features/tasks/domain/repositories/task_repository.dart';
import 'package:taskbite/features/tasks/presentation/cubit/tasks_state.dart';

/// Cubit that keeps the dashboard in sync with the persisted task box.
///
/// [load] subscribes to the repository stream; every create/edit/status
/// change/delete is re-emitted automatically, so the UI never holds a stale
/// copy. Mutations are thin passthroughs to the repository – all business
/// rules (timestamps, validation at the boundary) live there.
class TasksCubit extends Cubit<TasksState> {
  TasksCubit(this._repository) : super(const TasksState());

  final TaskRepository _repository;
  StreamSubscription<List<StoredTask>>? _subscription;

  TaskRepository get repository => _repository;

  Future<void> load() async {
    try {
      // Re-evaluate the centralized overdue rule before the first snapshot so
      // a task that expired while the app was closed is already Failed.
      await _repository.evaluateOverdue();
      _emitSnapshot(await _repository.loadTasks());
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, errorMessage: 'tasksLoadError'));
      }
    }
    _subscription ??= _repository.watchTasks().listen(
      _emitSnapshot,
      onError: (Object error) {
        if (!isClosed) {
          emit(
            state.copyWith(isLoading: false, errorMessage: 'tasksLoadError'),
          );
        }
      },
    );
  }

  /// Re-applies the overdue rule when the app comes back to the foreground,
  /// which is the case the closing app cannot handle with a timer.
  Future<void> onAppResumed() => _evaluateOverdueSafely();

  Future<void> _evaluateOverdueSafely() async {
    try {
      await _repository.evaluateOverdue();
    } catch (_) {
      // Keep the last good snapshot: failing to re-evaluate an overdue task
      // must never take the whole dashboard down.
    }
  }

  void _emitSnapshot(List<StoredTask> raw) {
    if (isClosed) return;
    emit(state.copyWith(tasks: raw, isLoading: false, clearError: true));
  }

  void search(String query) {
    if (isClosed) return;
    emit(state.copyWith(searchQuery: query));
  }

  Future<void> addTask({
    required String title,
    required String content,
    DateTime? dueDate,
  }) async {
    await _repository.createTask(
      title: title,
      content: content,
      dueDate: dueDate,
    );
    await _evaluateOverdueSafely();
  }

  Future<void> updateTask({
    required dynamic key,
    required String title,
    required String content,
    DateTime? dueDate,
  }) async {
    await _repository.updateTask(
      key: key,
      title: title,
      content: content,
      dueDate: dueDate,
    );
    await _evaluateOverdueSafely();
  }

  Future<void> changeStatus({
    required dynamic key,
    required TaskStatus status,
  }) async {
    await _repository.updateStatus(key: key, status: status);
    // A task moved back to active must be re-checked: an expired unfinished
    // task cannot remain incorrectly active.
    await _evaluateOverdueSafely();
  }

  Future<void> removeTask({required dynamic key}) async {
    await _repository.deleteTask(key: key);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    return super.close();
  }
}
