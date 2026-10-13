import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/home/presentation/screens/home_screen.dart';
import 'package:taskbite/features/home/presentation/widgets/custom_bottom_navigation_bar.dart';
import 'package:taskbite/features/tasks/presentation/cubit/tasks_cubit.dart';
import 'package:taskbite/features/tasks/presentation/widgets/primary_action_bar.dart';

import '../../support/fakes.dart';

Widget _app(TasksCubit cubit) {
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
      child: const HomeScreen(),
    ),
  );
}

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(CustomBottomNavigationBar),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
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

  testWidgets('docked create actions only appear on the New tab', (
    tester,
  ) async {
    await cubit.load();

    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();

    expect(find.byType(PrimaryActionBar), findsOneWidget);

    for (final label in ['In progress', 'Completed', 'Failed']) {
      await _tapTab(tester, label);
      expect(
        find.byType(PrimaryActionBar),
        findsNothing,
        reason: 'create actions must be unavailable on the $label tab',
      );
    }

    await _tapTab(tester, 'New');
    expect(find.byType(PrimaryActionBar), findsOneWidget);
  });

  testWidgets('the Failed tab lists only missed-deadline tasks', (
    tester,
  ) async {
    await repository.createTask(
      title: 'Overdue paperwork',
      content: '',
      dueDate: DateTime.now().subtract(const Duration(days: 3)),
    );
    await repository.createTask(title: 'Fresh idea', content: '');
    await cubit.load();

    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();
    await _tapTab(tester, 'Failed');

    expect(find.text('Overdue paperwork'), findsOneWidget);
    expect(find.text('Fresh idea'), findsNothing);
    expect(find.text('Deadline missed'), findsOneWidget);
    expect(find.byType(PrimaryActionBar), findsNothing);
  });
}
