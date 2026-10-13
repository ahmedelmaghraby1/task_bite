import 'package:flutter_test/flutter_test.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/presentation/cubit/tasks_cubit.dart';

import '../../support/fakes.dart';

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('TasksCubit', () {
    late FakeTaskRepository repository;
    late TasksCubit cubit;

    setUp(() {
      repository = FakeTaskRepository();
      cubit = TasksCubit(repository);
    });

    tearDown(() async {
      await cubit.close();
      await repository.dispose();
    });

    test('loads an empty snapshot without errors', () async {
      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.totalCount, 0);
      expect(cubit.state.errorMessage, isNull);
    });

    test('surfaces a load error instead of crashing', () async {
      repository.loadError = StateError('hive unavailable');
      await cubit.load();

      expect(cubit.state.errorMessage, 'tasksLoadError');
      expect(cubit.state.totalCount, 0);
    });

    test('recovered from a load error when new data arrives', () async {
      repository.loadError = StateError('hive unavailable');
      await cubit.load();
      expect(cubit.state.errorMessage, 'tasksLoadError');

      repository.loadError = null;
      await repository.createTask(title: 'Recovered', content: '');
      await _settle();

      expect(cubit.state.totalCount, 1);
      expect(cubit.state.errorMessage, isNull);
    });

    test('derived counts reflect the persisted data', () async {
      await cubit.load();
      await cubit.addTask(title: 'one', content: 'a');
      final firstKey = repository.items.first.key;
      await cubit.changeStatus(key: firstKey, status: TaskStatus.pending);
      await cubit.addTask(title: 'two', content: 'b');
      final secondKey = repository.items.last.key;
      await cubit.changeStatus(key: secondKey, status: TaskStatus.completed);
      await cubit.addTask(title: 'three', content: 'c');
      await _settle();

      final state = cubit.state;
      expect(state.totalCount, 3);
      expect(state.newCount, 1);
      expect(state.pendingCount, 1);
      expect(state.completedCount, 1);
      expect(state.activeCount, 2);
      expect(state.completionRatio, closeTo(1 / 3, 0.001));
      expect(state.byStatus(TaskStatus.completed), hasLength(1));
      expect(state.byStatus(TaskStatus.completed).single.key, secondKey);
    });

    test('search matches title and content, case-insensitive', () async {
      await cubit.load();
      await cubit.addTask(title: 'Buy Milk', content: 'from the store');
      await cubit.addTask(title: 'Write report', content: 'about milk prices');
      await cubit.addTask(title: 'Call plumber', content: 'fix the sink');
      await _settle();

      cubit.search('MILK');
      await _settle();
      expect(cubit.state.hasQuery, isTrue);
      expect(cubit.state.searchAll(), hasLength(2));
      expect(cubit.state.byStatus(TaskStatus.newTask), hasLength(2));

      cubit.search('sink');
      await _settle();
      expect(cubit.state.searchAll(), hasLength(1));
      expect(cubit.state.searchAll().single.task.title, 'Call plumber');

      cubit.search('   ');
      await _settle();
      expect(cubit.state.hasQuery, isFalse);
      expect(cubit.state.searchAll(), hasLength(3));
    });

    test('status transitions move tasks between buckets', () async {
      await cubit.load();
      await cubit.addTask(title: 't', content: 'c');
      final key = repository.items.single.key;

      await cubit.changeStatus(key: key, status: TaskStatus.completed);
      await _settle();
      expect(cubit.state.completedCount, 1);
      expect(cubit.state.newCount, 0);

      await cubit.changeStatus(key: key, status: TaskStatus.newTask);
      await _settle();
      expect(cubit.state.completedCount, 0);
      expect(cubit.state.newCount, 1);
    });

    test('updateTask persists edited fields', () async {
      // Use future dates: a past due date would (correctly) auto-fail the task,
      // which is covered separately.
      final firstDue = DateTime.now().add(const Duration(days: 5));
      final secondDue = DateTime.now().add(const Duration(days: 10));
      await cubit.load();
      await cubit.addTask(title: 'old', content: 'x', dueDate: firstDue);
      final key = repository.items.single.key;

      await cubit.updateTask(
        key: key,
        title: 'new',
        content: 'y',
        dueDate: secondDue,
      );
      await _settle();

      final updated = repository.items.single.task;
      expect(updated.title, 'new');
      expect(updated.content, 'y');
      expect(updated.dueDate, secondDue);
      expect(cubit.state.byStatus(TaskStatus.newTask).single.task.title, 'new');
    });

    test('removeTask deletes through the repository', () async {
      await cubit.load();
      await cubit.addTask(title: 'bye', content: '');
      final key = repository.items.single.key;

      await cubit.removeTask(key: key);
      await _settle();

      expect(repository.deleteCalls, 1);
      expect(cubit.state.totalCount, 0);
    });

    test('reacts to external repository mutations via the stream', () async {
      await cubit.load();
      await repository.createTask(title: 'From outside', content: '');
      await _settle();

      expect(cubit.state.totalCount, 1);
    });

    test('searching while empty keeps the state consistent', () async {
      await cubit.load();
      cubit.search('nothing');
      await _settle();

      expect(cubit.state.hasQuery, isTrue);
      expect(cubit.state.searchAll(), isEmpty);
      expect(cubit.state.byStatus(TaskStatus.newTask), isEmpty);
    });

    group('overdue evaluation', () {
      final past = DateTime.now().subtract(const Duration(days: 3));

      test(
        'an unfinished task past its due date becomes failed on load',
        () async {
          await repository.createTask(
            title: 'Late',
            content: '',
            dueDate: past,
          );

          await cubit.load();

          expect(cubit.state.failedCount, 1);
          expect(cubit.state.newCount, 0);
          expect(cubit.state.totalCount, 1);
          expect(
            cubit.state.byStatus(TaskStatus.failed).single.task.title,
            'Late',
          );
          // All tasks includes the failed task exactly once.
          expect(cubit.state.totalCount, cubit.state.failedCount);
        },
      );

      test('a task without a due date never becomes failed', () async {
        await repository.createTask(title: 'Someday', content: '');

        await cubit.load();

        expect(cubit.state.failedCount, 0);
        expect(cubit.state.newCount, 1);
      });

      test('a due date in the future is not failed', () async {
        await repository.createTask(
          title: 'Soon',
          content: '',
          dueDate: DateTime.now().add(const Duration(days: 2)),
        );

        await cubit.load();

        expect(cubit.state.failedCount, 0);
        expect(cubit.state.newCount, 1);
      });

      test('a completed task past its due date never becomes failed', () async {
        final stored = await repository.createTask(
          title: 'Done',
          content: '',
          dueDate: past,
        );
        await repository.updateStatus(
          key: stored.key,
          status: TaskStatus.completed,
        );

        await cubit.load();

        expect(cubit.state.failedCount, 0);
        expect(cubit.state.completedCount, 1);
      });

      test(
        'repeated evaluation neither duplicates nor corrupts tasks',
        () async {
          await repository.createTask(
            title: 'Late',
            content: '',
            dueDate: past,
          );

          await cubit.load();
          expect(await repository.evaluateOverdue(), 0);
          expect(await repository.evaluateOverdue(), 0);
          await cubit.onAppResumed();
          await _settle();

          expect(cubit.state.totalCount, 1);
          expect(cubit.state.failedCount, 1);
          expect(cubit.state.newCount, 0);
        },
      );

      test('app resume re-evaluates tasks created while backgrounded', () async {
        await cubit.load();
        // A task created outside the cubit (e.g. by a resume-time sync) with a
        // past date is not evaluated until the resume hook runs.
        await repository.createTask(title: 'Late', content: '', dueDate: past);
        await _settle();
        expect(cubit.state.failedCount, 0);

        await cubit.onAppResumed();
        await _settle();

        expect(cubit.state.failedCount, 1);
      });

      test(
        'reopening an overdue failed task does not leave it active',
        () async {
          await repository.createTask(
            title: 'Late',
            content: '',
            dueDate: past,
          );
          await cubit.load();
          final key = repository.items.single.key;
          expect(cubit.state.failedCount, 1);

          await cubit.changeStatus(key: key, status: TaskStatus.newTask);
          await _settle();

          // The deadline is still in the past, so it must return to Failed.
          expect(cubit.state.failedCount, 1);
          expect(cubit.state.newCount, 0);
        },
      );

      test(
        'clearing the due date lets a failed task become active again',
        () async {
          await repository.createTask(
            title: 'Late',
            content: '',
            dueDate: past,
          );
          await cubit.load();
          final key = repository.items.single.key;

          await cubit.updateTask(
            key: key,
            title: 'Late',
            content: '',
            dueDate: null,
          );
          await _settle();
          await cubit.changeStatus(key: key, status: TaskStatus.newTask);
          await _settle();

          expect(cubit.state.newCount, 1);
          expect(cubit.state.failedCount, 0);
        },
      );

      test(
        'search combines with the selected status without leaking',
        () async {
          await repository.createTask(
            title: 'Overdue milk',
            content: '',
            dueDate: past,
          );
          await repository.createTask(title: 'Fresh milk', content: '');
          await repository.createTask(title: 'Fresh report', content: '');
          await cubit.load();

          cubit.search('milk');
          await _settle();

          expect(
            cubit.state.byStatus(TaskStatus.failed).single.task.title,
            'Overdue milk',
          );
          expect(cubit.state.byStatus(TaskStatus.newTask), hasLength(1));
          expect(
            cubit.state.byStatus(TaskStatus.newTask).single.task.title,
            'Fresh milk',
          );
          expect(cubit.state.byStatus(TaskStatus.completed), isEmpty);
        },
      );
    });
  });
}
