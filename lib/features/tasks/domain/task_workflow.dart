import 'package:taskbite/features/tasks/data/models/task_model.dart';

/// The single source of truth for status transitions.
///
/// Every status change in the UI (task cards, details screen, reopen/restart)
/// goes through [next] so the workflow cannot drift between widgets. The
/// overdue rule is *not* encoded here: a task moved back to an active status is
/// re-evaluated by the repository, which is what keeps an expired deadline
/// from silently parking in an active list.
abstract final class TaskWorkflow {
  /// The status reached by the primary "progress" action on [current].
  ///
  /// * `new` → `in progress` (start)
  /// * `in progress` → `completed` (complete)
  /// * `completed` → `new` (reopen)
  /// * `failed` → `new` (restart; the overdue rule then decides whether it
  ///   stays active or returns to Failed because the deadline is still past).
  static TaskStatus next(TaskStatus current) => switch (current) {
    TaskStatus.newTask => TaskStatus.pending,
    TaskStatus.pending => TaskStatus.completed,
    TaskStatus.completed => TaskStatus.newTask,
    TaskStatus.failed => TaskStatus.newTask,
  };

  /// Localization key for the label of the action that advances [current].
  static String nextActionLabelKey(TaskStatus current) => switch (current) {
    TaskStatus.newTask => 'start',
    TaskStatus.pending => 'complete',
    TaskStatus.completed => 'reopen',
    TaskStatus.failed => 'reopen',
  };
}

/// Where task creation is allowed.
///
/// Tasks may only be created from the New tab. Both the docked create actions
/// and the list empty states consult this policy, so the rule is enforced in
/// one place rather than by hiding a single button.
abstract final class TaskCreationPolicy {
  static bool canCreateFrom(TaskStatus tabStatus) =>
      tabStatus == TaskStatus.newTask;
}
