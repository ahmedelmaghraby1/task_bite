import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/domain/task_workflow.dart';
import 'package:taskbite/features/tasks/presentation/cubit/task_composer_state.dart';
import 'package:taskbite/features/tasks/presentation/cubit/tasks_cubit.dart';
import 'package:taskbite/features/tasks/presentation/cubit/tasks_state.dart';
import 'package:taskbite/features/tasks/presentation/widgets/empty_state.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_composer_sheet.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_tile.dart';

/// Filtered, real-time list for one task status.
///
/// Reads the live [TasksCubit] snapshot (which is fed straight from Hive) and
/// renders the appropriate empty state: no tasks at all, no search matches or
/// no tasks in this status. The shared search query is applied by the state,
/// so the list stays in sync with the dashboard search field.
class TaskStatusList extends StatelessWidget {
  const TaskStatusList({super.key, required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage != null && state.tasks.isEmpty) {
          return EmptyState(
            icon: Icons.cloud_off_rounded,
            titleKey: 'tasksLoadError',
            action: FilledButton.icon(
              onPressed: () => context.read<TasksCubit>().load(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text('retry'.tr(context)),
            ),
          );
        }

        final items = state.byStatus(status);
        if (items.isEmpty) {
          return _emptyState(context, state);
        }

        return ListView.separated(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          // Rebuild list items when the query changes so filtered results
          // animate/paint correctly.
          itemBuilder: (context, index) {
            final entry = items[index];
            return TaskTile(
              key: ValueKey('${status.name}-${entry.key}'),
              task: entry.task,
              taskKey: entry.key,
            );
          },
        );
      },
    );
  }

  Widget _emptyState(BuildContext context, TasksState state) {
    if (state.hasQuery) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        titleKey: 'searchEmptyTitle',
        messageKey: 'searchEmptyMessage',
      );
    }
    if (state.totalCount == 0) {
      // Creation is only offered from the New tab (single creation policy).
      if (TaskCreationPolicy.canCreateFrom(status)) {
        return EmptyState(
          icon: Icons.checklist_rounded,
          titleKey: 'tasksEmptyTitle',
          messageKey: 'tasksEmptyMessage',
          action: FilledButton.icon(
            onPressed:
                () => showTaskComposer(context, initialTab: ComposerTab.voice),
            icon: const Icon(Icons.mic_rounded),
            label: Text('speakATask'.tr(context)),
          ),
        );
      }
      return _statusEmptyState();
    }
    if (status == TaskStatus.pending &&
        state.newCount == 0 &&
        state.failedCount == 0) {
      // Nothing to start and nothing missed: every remaining task is done.
      return const EmptyState(
        icon: Icons.celebration_rounded,
        titleKey: 'allDoneTitle',
        messageKey: 'allDoneMessage',
      );
    }
    return _statusEmptyState();
  }

  Widget _statusEmptyState() => EmptyState(
    icon: _emptyIcon,
    titleKey: 'statusEmptyTitle',
    messageKey: 'statusEmptyMessage',
  );

  IconData get _emptyIcon => switch (status) {
    TaskStatus.newTask => Icons.new_releases_rounded,
    TaskStatus.pending => Icons.pending_actions_rounded,
    TaskStatus.completed => Icons.check_circle_outline_rounded,
    TaskStatus.failed => Icons.error_outline_rounded,
  };
}
