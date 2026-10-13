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
  @HiveField(3)
  DateTime? dueDate;
  @HiveField(4)
  DateTime? createdAt;
  @HiveField(5)
  DateTime? updatedAt;

  TaskModel({
    required this.title,
    required this.content,
    this.status = TaskStatus.newTask,
    this.dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Marks the task as touched, keeping `createdAt` stable.
  void markUpdated({DateTime? at}) {
    updatedAt = at ?? DateTime.now();
  }

  /// Single source of truth for the overdue time condition.
  ///
  /// A task is overdue only when it has a due date, has not been completed and
  /// the due calendar day has already ended. The due date is a calendar day
  /// (midnight), so a task due *today* is not overdue until tomorrow; a task
  /// with no due date is never overdue. [now] is injectable for testing.
  bool isOverdue({DateTime? now}) {
    if (status == TaskStatus.completed) return false;
    final due = dueDate;
    if (due == null) return false;
    final reference = now ?? DateTime.now();
    final startOfToday = DateTime(
      reference.year,
      reference.month,
      reference.day,
    );
    return due.isBefore(startOfToday);
  }

  /// Whether this task should be moved to [TaskStatus.failed] by the
  /// centralized overdue evaluation. Already-failed tasks are left untouched so
  /// evaluation is idempotent and an existing Failed task is never rewritten.
  bool shouldBecomeFailed({DateTime? now}) =>
      status != TaskStatus.failed && isOverdue(now: now);

  TaskModel copyWith({
    String? title,
    String? content,
    TaskStatus? status,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool dueDateExplicitlySet = false,
  }) {
    final shouldClear = clearDueDate || dueDateExplicitlySet;
    DateTime? nextDueDate;
    if (shouldClear) {
      nextDueDate = dueDateExplicitlySet ? dueDate : null;
    } else {
      nextDueDate = dueDate ?? this.dueDate;
    }
    return TaskModel(
      title: title ?? this.title,
      content: content ?? this.content,
      status: status ?? this.status,
      dueDate: nextDueDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

@HiveType(typeId: 1)
enum TaskStatus {
  @HiveField(0)
  newTask,
  @HiveField(1)
  pending,
  @HiveField(2)
  completed,

  /// An unfinished task whose due date has passed. Persisted like every other
  /// status; the numeric index (3) was appended, so records written by older
  /// builds (0/1/2) keep deserializing to the same statuses.
  @HiveField(3)
  failed,
}

extension TaskStatusX on TaskStatus {
  /// Human-facing semantic label for the status. The stored enum keeps its
  /// original meaning (`pending` = actively worked on) and the UI reads it
  /// through this getter so labels can be improved without touching data.
  bool get isActive => this == TaskStatus.newTask || this == TaskStatus.pending;
}
