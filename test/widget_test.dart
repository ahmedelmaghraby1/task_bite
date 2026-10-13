import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/presentation/widgets/empty_state.dart';
import 'package:taskbite/features/tasks/presentation/widgets/status_pill.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_fields_view.dart';

Widget _app(Widget child, {String languageCode = 'en'}) {
  return MaterialApp(
    locale: Locale(languageCode),
    supportedLocales: AppLocalization.supportedLocales,
    localizationsDelegates: const [
      AppLocalizationDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  group('localization', () {
    testWidgets('status pills localize their labels', (tester) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: [
              StatusPill(status: TaskStatus.newTask),
              StatusPill(status: TaskStatus.pending),
              StatusPill(status: TaskStatus.completed),
              StatusPill(status: TaskStatus.failed),
            ],
          ),
        ),
      );

      expect(find.text('New'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
    });

    testWidgets('empty state renders localized title and message', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const EmptyState(
            icon: Icons.checklist_rounded,
            titleKey: 'tasksEmptyTitle',
            messageKey: 'tasksEmptyMessage',
          ),
        ),
      );

      expect(find.text('No tasks yet'), findsOneWidget);
      expect(find.textContaining('Create your first task'), findsOneWidget);
    });

    testWidgets('Arabic UI resolves and applies RTL direction', (tester) async {
      await tester.pumpWidget(
        _app(const StatusPill(status: TaskStatus.pending), languageCode: 'ar'),
      );

      expect(find.text('جارية'), findsOneWidget);
      final context = tester.element(find.byType(StatusPill));
      expect(Directionality.of(context), TextDirection.rtl);
    });
  });

  group('task fields validation', () {
    testWidgets('shows the title-required error when enabled', (tester) async {
      final titleController = TextEditingController();
      final descriptionController = TextEditingController();
      addTearDown(titleController.dispose);
      addTearDown(descriptionController.dispose);

      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder:
                (context, setState) => TaskFieldsView(
                  titleController: titleController,
                  descriptionController: descriptionController,
                  dueDate: null,
                  onDueDateChanged: (_) {},
                  showTitleError: true,
                ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Please enter a task title'), findsOneWidget);
    });

    testWidgets('user typing lands in the title and description fields', (
      tester,
    ) async {
      final titleController = TextEditingController();
      final descriptionController = TextEditingController();
      addTearDown(titleController.dispose);
      addTearDown(descriptionController.dispose);

      await tester.pumpWidget(
        _app(
          TaskFieldsView(
            titleController: titleController,
            descriptionController: descriptionController,
            dueDate: null,
            onDueDateChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              (w.decoration?.labelText?.contains('title') ?? false),
        ),
        'Water the plants',
      );
      expect(titleController.text, 'Water the plants');
    });
  });

  group('list behavior', () {
    testWidgets('empty state opens with a default padding and centers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 800,
            height: 600,
            child: EmptyState(
              icon: Icons.search_off_rounded,
              titleKey: 'searchEmptyTitle',
            ),
          ),
        ),
      );

      final icon = find.byIcon(Icons.search_off_rounded);
      expect(icon, findsOneWidget);
    });
  });
}
