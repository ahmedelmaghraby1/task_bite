import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/data/repositories/hive_task_repository.dart';
import 'package:taskbite/features/tasks/domain/models/stored_task.dart';

void main() {
  late Directory dir;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TaskStatusAdapter());
    }
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('taskbite_hive_test');
    Hive.init(dir.path);
    await Hive.openBox<TaskModel>('tasks');
  });

  tearDown(() async {
    await Hive.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Box<TaskModel> box() => Hive.box<TaskModel>('tasks');

  group('HiveTaskRepository', () {
    test('creates a task with defaults and trims the fields', () async {
      final repository = HiveTaskRepository();
      final stored = await repository.createTask(
        title: '  Buy milk  ',
        content: '  From the corner store  ',
      );

      expect(box().length, 1);
      expect(stored.task.title, 'Buy milk');
      expect(stored.task.content, 'From the corner store');
      expect(stored.task.status, TaskStatus.newTask);
      expect(stored.task.dueDate, isNull);
      expect(stored.task.createdAt, isNotNull);
      expect(stored.task.updatedAt, isNotNull);
    });

    test('persists all fields across a reopen', () async {
      final repository = HiveTaskRepository();
      final dueDate = DateTime(2026, 12, 31);
      final created = await repository.createTask(
        title: 'Ship release',
        content: '- bump version',
        dueDate: dueDate,
      );
      await repository.updateStatus(
        key: created.key,
        status: TaskStatus.pending,
      );

      // Simulate an app restart: close and re-open the box on disk.
      await box().close();
      final reopened = await Hive.openBox<TaskModel>('tasks');

      final stored = reopened.toMap().entries.single.value;
      expect(stored.title, 'Ship release');
      expect(stored.content, '- bump version');
      expect(stored.dueDate, dueDate);
      expect(stored.status, TaskStatus.pending);
      expect(stored.createdAt, isNotNull);
      expect(stored.updatedAt, isNotNull);
    });

    test('an update keeps createdAt and bumps updatedAt', () async {
      final repository = HiveTaskRepository();
      final created = await repository.createTask(
        title: 'Original',
        content: '',
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await repository.updateTask(
        key: created.key,
        title: 'Edited',
        content: 'New body',
        dueDate: DateTime(2026, 1, 1),
      );

      final updated = box().get(created.key)!;
      expect(updated.title, 'Edited');
      expect(updated.content, 'New body');
      expect(updated.dueDate, DateTime(2026, 1, 1));
      expect(updated.createdAt, created.task.createdAt);
      expect(updated.updatedAt!.isAfter(updated.createdAt!), isTrue);
    });

    test('clearing the due date persists as null', () async {
      final repository = HiveTaskRepository();
      final created = await repository.createTask(
        title: 'Has a date',
        content: '',
        dueDate: DateTime(2026, 1, 1),
      );
      await repository.updateTask(
        key: created.key,
        title: 'Has a date',
        content: '',
        dueDate: null,
      );
      expect(box().get(created.key)!.dueDate, isNull);
    });

    test('status transitions persist', () async {
      final repository = HiveTaskRepository();
      final stored = await repository.createTask(title: 'Task', content: '');

      await repository.updateStatus(
        key: stored.key,
        status: TaskStatus.pending,
      );
      expect(box().get(stored.key)!.status, TaskStatus.pending);

      await repository.updateStatus(
        key: stored.key,
        status: TaskStatus.completed,
      );
      expect(box().get(stored.key)!.status, TaskStatus.completed);

      await repository.updateStatus(key: stored.key, status: TaskStatus.failed);
      expect(box().get(stored.key)!.status, TaskStatus.failed);
    });

    test('delete removes the task', () async {
      final repository = HiveTaskRepository();
      final stored = await repository.createTask(title: 'Doomed', content: '');

      await repository.deleteTask(key: stored.key);

      expect(box().length, 0);
      expect(repository.snapshot(), isEmpty);
    });

    test('watchTasks emits snapshots on mutations', () async {
      final repository = HiveTaskRepository();
      final emissions = <List<StoredTask>>[];
      final subscription = repository.watchTasks().listen(emissions.add);

      await repository.createTask(title: 'Streamed', content: '');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(emissions, isNotEmpty);
      expect(emissions.last, hasLength(1));
      expect(emissions.last.single.task.title, 'Streamed');

      await subscription.cancel();
    });

    test(
      'reads legacy 3-field records safely (dueDate/createdAt/updatedAt)',
      () {
        // Simulate a record written before fields 3-5 existed: only 3 fields,
        // written with the exact frame layout the old generated adapter used.
        final writer =
            BinaryWriterImpl(Hive)
              ..writeByte(3)
              ..writeByte(0)
              ..write('legacy title')
              ..writeByte(1)
              ..write('legacy body')
              ..writeByte(2)
              ..write(TaskStatus.newTask);
        final bytes = writer.toBytes();

        final reader = BinaryReaderImpl(bytes, Hive, bytes.length);
        final legacy = TaskModelAdapter().read(reader);

        expect(legacy.title, 'legacy title');
        expect(legacy.content, 'legacy body');
        expect(legacy.status, TaskStatus.newTask);
        // Field 3 (dueDate) is absent in legacy records and stays null: the
        // model does not fabricate a due date.
        expect(legacy.dueDate, isNull);
        // The model defaults the two time stamps introduced with fields 4-5
        // so upgraded legacy records still render timestamps everywhere.
        expect(legacy.createdAt, isNotNull);
        expect(legacy.updatedAt, isNotNull);
        // A record without a due date must never be swept into Failed.
        expect(legacy.shouldBecomeFailed(), isFalse);
      },
    );

    test('loadTasks returns the current snapshot', () async {
      final repository = HiveTaskRepository();
      await repository.createTask(title: 'Snap', content: '');
      await repository.createTask(title: 'Shot', content: '');

      final snapshot = await repository.loadTasks();

      expect(snapshot, hasLength(2));
      expect(snapshot.map((s) => s.task.title), containsAll(['Snap', 'Shot']));
    });

    group('evaluateOverdue', () {
      test(
        'fails only unfinished tasks whose calendar day has passed',
        () async {
          final repository = HiveTaskRepository();
          final past = DateTime.now().subtract(const Duration(days: 2));
          final future = DateTime.now().add(const Duration(days: 2));
          final late = await repository.createTask(
            title: 'Late',
            content: '',
            dueDate: past,
          );
          final noDate = await repository.createTask(
            title: 'No date',
            content: '',
          );
          final soon = await repository.createTask(
            title: 'Soon',
            content: '',
            dueDate: future,
          );
          final done = await repository.createTask(
            title: 'Done',
            content: '',
            dueDate: past,
          );
          await repository.updateStatus(
            key: done.key,
            status: TaskStatus.completed,
          );

          final changed = await repository.evaluateOverdue();

          expect(changed, 1);
          expect(box().get(late.key)!.status, TaskStatus.failed);
          expect(box().get(noDate.key)!.status, TaskStatus.newTask);
          expect(box().get(soon.key)!.status, TaskStatus.newTask);
          expect(box().get(done.key)!.status, TaskStatus.completed);
        },
      );

      test('is idempotent and never rewrites an already failed task', () async {
        final repository = HiveTaskRepository();
        final stored = await repository.createTask(
          title: 'Late',
          content: '',
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
        );

        expect(await repository.evaluateOverdue(), 1);
        expect(box().get(stored.key)!.status, TaskStatus.failed);
        // A second pass changes nothing and keeps the task exactly once.
        expect(await repository.evaluateOverdue(), 0);
        expect(box().length, 1);
      });

      test('persists the failed status across a reopen', () async {
        final repository = HiveTaskRepository();
        final stored = await repository.createTask(
          title: 'Late',
          content: '',
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
        );
        await repository.evaluateOverdue();

        await box().close();
        final reopened = await Hive.openBox<TaskModel>('tasks');

        expect(reopened.get(stored.key)!.status, TaskStatus.failed);
      });
    });
  });
}
