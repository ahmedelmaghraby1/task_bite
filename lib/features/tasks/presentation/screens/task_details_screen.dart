import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/core/themes/colors.dart';
import 'package:taskbite/core/utils/alert_dialog.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/domain/models/stored_task.dart';
import 'package:taskbite/features/tasks/domain/task_workflow.dart';
import 'package:taskbite/features/tasks/presentation/cubit/tasks_cubit.dart';
import 'package:taskbite/features/tasks/presentation/cubit/tasks_state.dart';
import 'package:taskbite/features/tasks/presentation/widgets/empty_state.dart';
import 'package:taskbite/features/tasks/presentation/widgets/missed_deadline_chip.dart';
import 'package:taskbite/features/tasks/presentation/widgets/status_pill.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_composer_sheet.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_fields_view.dart';

/// Full task view with status transitions, edit and delete.
///
/// The task is read from the live [TasksCubit] snapshot rather than from the
/// navigation argument, so edits and status changes made anywhere are
/// reflected immediately and a deleted task shows a graceful empty state.
class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({
    super.key,
    required this.task,
    required this.taskKey,
  });

  final TaskModel task;
  final dynamic taskKey;

  StoredTask? _find(TasksState state) {
    for (final entry in state.tasks) {
      if (entry.key == taskKey) return entry;
    }
    return null;
  }

  void _confirmDelete(BuildContext context) {
    showAlertDialog(
      context,
      message: 'deletingMessage',
      yesTitle: 'yes',
      noTitle: 'no',
      onYesFunction: () {
        context.read<TasksCubit>().removeTask(key: taskKey);
        Navigator.of(context)
          ..pop() // close the dialog
          ..pop(); // leave the details screen
      },
    );
  }

  void _edit(BuildContext context, TaskModel current) {
    showTaskComposer(
      context,
      existing: StoredTask(key: taskKey, task: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('taskDetails'.tr(context)),
        actions: [
          BlocBuilder<TasksCubit, TasksState>(
            builder: (context, state) {
              final entry = _find(state);
              if (entry == null) return const SizedBox.shrink();
              return Row(
                children: [
                  IconButton(
                    tooltip: 'editTask'.tr(context),
                    onPressed: () => _edit(context, entry.task),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'deleteTask'.tr(context),
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          final entry = _find(state);
          if (entry == null) {
            return EmptyState(
              icon: Icons.delete_outline_rounded,
              titleKey: 'taskDeleted',
              action: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text('back'.tr(context)),
              ),
            );
          }
          return _DetailsBody(entry: entry);
        },
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.entry});

  final StoredTask entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final task = entry.task;
    final muted = Theme.of(context).textTheme.bodySmall?.color;

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 32),
      children: [
        Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusPill(status: task.status),
            if (task.dueDate != null)
              _DueChip(dueDate: task.dueDate!, overdue: task.isOverdue()),
            if (task.status == TaskStatus.failed)
              const MissedDeadlineChip(compact: false),
          ],
        ),
        const SizedBox(height: 20),
        if (task.content.trim().isNotEmpty) ...[
          _SectionLabel(labelKey: 'description'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(
              task.content.trim(),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
        ],
        _MetaRows(task: task, muted: muted),
        const SizedBox(height: 24),
        _StatusActions(taskKey: entry.key, status: task.status),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.labelKey});

  final String labelKey;

  @override
  Widget build(BuildContext context) {
    return Text(
      labelKey.tr(context),
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
}

class _MetaRows extends StatelessWidget {
  const _MetaRows({required this.task, required this.muted});

  final TaskModel task;
  final Color? muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetaRow(
          icon: Icons.calendar_today_rounded,
          labelKey: 'created',
          value: _formatTimestamp(task.createdAt),
          muted: muted,
        ),
        const SizedBox(height: 8),
        _MetaRow(
          icon: Icons.update_rounded,
          labelKey: 'updated',
          value: _formatTimestamp(task.updatedAt),
          muted: muted,
        ),
      ],
    );
  }

  static String _formatTimestamp(DateTime? value) {
    if (value == null) return '—';
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '${TaskFieldsView.formatDate(value)}  $h:$m';
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.labelKey,
    required this.value,
    required this.muted,
  });

  final IconData icon;
  final String labelKey;
  final String value;
  final Color? muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: muted),
        const SizedBox(width: 8),
        Text(
          '${labelKey.tr(context)}: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}

class _StatusActions extends StatelessWidget {
  const _StatusActions({required this.taskKey, required this.status});

  final dynamic taskKey;
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      TaskStatus.newTask => Icons.play_arrow_rounded,
      TaskStatus.pending => Icons.check_rounded,
      TaskStatus.completed => Icons.replay_rounded,
      TaskStatus.failed => Icons.replay_rounded,
    };
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed:
            () => context.read<TasksCubit>().changeStatus(
              key: taskKey,
              status: TaskWorkflow.next(status),
            ),
        icon: Icon(icon),
        label: Text(TaskWorkflow.nextActionLabelKey(status).tr(context)),
        style: FilledButton.styleFrom(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

class _DueChip extends StatelessWidget {
  const _DueChip({required this.dueDate, required this.overdue});

  final DateTime dueDate;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final color =
        overdue ? Theme.of(context).colorScheme.error : AppColors.warning;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            TaskFieldsView.formatDate(dueDate),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
