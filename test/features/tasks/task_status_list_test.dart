import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/presentation/cubit/tasks_cubit.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_status_list.dart';

import '../../support/fakes.dart';

Widget _app(TasksCubit cubit, TaskStatus status) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalization.supportedLocales,
    localizationsDelegates: const [
      AppLocalizationDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: BlocProvider<TasksCubit>.value(
      value: cubit,
      child: Scaffold(body: TaskStatusList(status: status)),
    ),
  );
}

void main() {
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

  testWidgets('only the New list offers the create action when empty', (
    tester,
  ) async {
    await cubit.load();

    for (final status in TaskStatus.values) {
      await tester.pumpWidget(_app(cubit, status));
      await tester.pumpAndSettle();

      if (status == TaskStatus.newTask) {
        expect(find.text('No tasks yet'), findsOneWidget);
        expect(find.text('Speak a task'), findsOneWidget);
      } else {
        expect(
          find.text('Speak a task'),
          findsNothing,
          reason: 'no creation entry point on the ${status.name} list',
        );
        expect(
          find.text('Nothing here yet'),
          findsOneWidget,
          reason: 'the ${status.name} list stays informational',
        );
      }
    }
  });

  testWidgets('the Failed list shows only failed tasks and no creation', (
    tester,
  ) async {
    await repository.createTask(
      title: 'Overdue',
      content: '',
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
    );
    await repository.createTask(title: 'Active', content: '');
    await cubit.load();

    await tester.pumpWidget(_app(cubit, TaskStatus.failed));
    await tester.pumpAndSettle();

    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Active'), findsNothing);
    expect(find.text('Deadline missed'), findsOneWidget);
    expect(find.text('Speak a task'), findsNothing);
  });

  testWidgets('the Pending list celebrates only when nothing failed', (
    tester,
  ) async {
    final done = await repository.createTask(title: 'Done', content: '');
    await repository.updateStatus(key: done.key, status: TaskStatus.completed);
    await cubit.load();

    await tester.pumpWidget(_app(cubit, TaskStatus.pending));
    await tester.pumpAndSettle();

    expect(find.text('All tasks completed'), findsOneWidget);
  });

  testWidgets('the Pending list does not celebrate while tasks are failed', (
    tester,
  ) async {
    await repository.createTask(
      title: 'Overdue',
      content: '',
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
    );
    await cubit.load();

    await tester.pumpWidget(_app(cubit, TaskStatus.pending));
    await tester.pumpAndSettle();

    expect(find.text('All tasks completed'), findsNothing);
    expect(find.text('Nothing here yet'), findsOneWidget);
  });
}
