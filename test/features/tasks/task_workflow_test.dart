import 'package:flutter_test/flutter_test.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/domain/task_workflow.dart';

void main() {
  group('TaskWorkflow', () {
    test('advances through the workflow and reopens finished tasks', () {
      expect(TaskWorkflow.next(TaskStatus.newTask), TaskStatus.pending);
      expect(TaskWorkflow.next(TaskStatus.pending), TaskStatus.completed);
      expect(TaskWorkflow.next(TaskStatus.completed), TaskStatus.newTask);
      // A failed task restarts as New; the overdue rule then decides whether
      // it can actually stay there.
      expect(TaskWorkflow.next(TaskStatus.failed), TaskStatus.newTask);
    });

    test('labels the action that advances a status', () {
      expect(TaskWorkflow.nextActionLabelKey(TaskStatus.newTask), 'start');
      expect(TaskWorkflow.nextActionLabelKey(TaskStatus.pending), 'complete');
      expect(TaskWorkflow.nextActionLabelKey(TaskStatus.completed), 'reopen');
      expect(TaskWorkflow.nextActionLabelKey(TaskStatus.failed), 'reopen');
    });

    test('creation is only allowed from the New status', () {
      expect(TaskCreationPolicy.canCreateFrom(TaskStatus.newTask), isTrue);
      expect(TaskCreationPolicy.canCreateFrom(TaskStatus.pending), isFalse);
      expect(TaskCreationPolicy.canCreateFrom(TaskStatus.completed), isFalse);
      expect(TaskCreationPolicy.canCreateFrom(TaskStatus.failed), isFalse);
    });
  });

  group('TaskModel overdue rule', () {
    // A fixed reference so the rule is tested without depending on the clock.
    final now = DateTime(2026, 10, 13, 9, 30);

    test('a task with no due date is never overdue and never failed', () {
      final task = TaskModel(title: 't', content: '');
      expect(task.isOverdue(now: now), isFalse);
      expect(task.shouldBecomeFailed(now: now), isFalse);
    });

    test('a due date later today is not overdue yet', () {
      final task = TaskModel(
        title: 't',
        content: '',
        dueDate: DateTime(2026, 10, 13),
      );
      expect(task.isOverdue(now: now), isFalse);
      expect(task.shouldBecomeFailed(now: now), isFalse);
    });

    test('a due date before today is overdue and should fail', () {
      final task = TaskModel(
        title: 't',
        content: '',
        dueDate: DateTime(2026, 10, 12),
      );
      expect(task.isOverdue(now: now), isTrue);
      expect(task.shouldBecomeFailed(now: now), isTrue);
    });

    test('a completed task is never overdue and never failed', () {
      final task = TaskModel(
        title: 't',
        content: '',
        status: TaskStatus.completed,
        dueDate: DateTime(2026, 1, 1),
      );
      expect(task.isOverdue(now: now), isFalse);
      expect(task.shouldBecomeFailed(now: now), isFalse);
    });

    test('an already failed task is never re-transitioned', () {
      final task = TaskModel(
        title: 't',
        content: '',
        status: TaskStatus.failed,
        dueDate: DateTime(2026, 1, 1),
      );
      // It is still "past its deadline" for display purposes...
      expect(task.isOverdue(now: now), isTrue);
      // ...but evaluation must leave it untouched so it is idempotent.
      expect(task.shouldBecomeFailed(now: now), isFalse);
    });
  });
}
