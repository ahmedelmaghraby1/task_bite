import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/core/routes/routes.dart';
import 'package:taskbite/core/themes/colors.dart';
import 'package:taskbite/core/utils/alert_dialog.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/domain/models/stored_task.dart';
import 'package:taskbite/features/tasks/domain/task_workflow.dart';
import 'package:taskbite/features/tasks/presentation/cubit/tasks_cubit.dart';
import 'package:taskbite/features/tasks/presentation/widgets/missed_deadline_chip.dart';
import 'package:taskbite/features/tasks/presentation/widgets/status_pill.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_composer_sheet.dart';

/// Polished task card used across the dashboard lists.
///
/// Shows the title, a two-line description preview, an optional due-date chip,
/// the status pill and contextual actions (advance status, edit, delete).
/// Completed tasks are visually softened and can be reopened; failed tasks
/// carry an explicit missed-deadline badge.
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, required this.taskKey});

  final TaskModel task;
  final dynamic taskKey;

  bool get _isCompleted => task.status == TaskStatus.completed;
  bool get _isFailed => task.status == TaskStatus.failed;
  bool get _isOverdue => task.isOverdue();

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  void _changeStatus(BuildContext context, TaskStatus status) {
    context.read<TasksCubit>().changeStatus(key: taskKey, status: status);
  }

  void _openDetails(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.taskDetailsScreen,
      arguments: {'taskKey': taskKey, 'task': task},
    );
  }

  void _edit(BuildContext context) {
    showTaskComposer(context, existing: StoredTask(key: taskKey, task: task));
  }

  void _confirmDelete(BuildContext context) {
    showAlertDialog(
      context,
      message: 'deletingMessage',
      yesTitle: 'yes',
      noTitle: 'no',
      onYesFunction: () {
        context.read<TasksCubit>().removeTask(key: taskKey);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    final onSurface = Theme.of(context).textTheme.bodyLarge?.color;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openDetails(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                              decoration:
                                  _isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                              decorationColor: muted,
                            ),
                          ),
                        ),
                        if (_isCompleted) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    ),
                    if (task.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.content.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: muted),
                      ),
                    ],
                    if (task.dueDate != null || _isFailed) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (task.dueDate != null)
                            _DueChip(
                              label: _formatDate(task.dueDate!),
                              overdue: _isOverdue,
                            ),
                          if (_isFailed) const MissedDeadlineChip(),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    StatusPill(status: task.status),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ProgressAction(
                    status: task.status,
                    onTap:
                        () => _changeStatus(
                          context,
                          TaskWorkflow.next(task.status),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconButton(
                        icon: Icons.edit_outlined,
                        tooltip: 'editTask'.tr(context),
                        color: scheme.primary,
                        onTap: () => _edit(context),
                      ),
                      const SizedBox(width: 4),
                      _IconButton(
                        icon: Icons.delete_outline_rounded,
                        tooltip: 'deleteTask'.tr(context),
                        color: scheme.error,
                        onTap: () => _confirmDelete(context),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueChip extends StatelessWidget {
  const _DueChip({required this.label, required this.overdue});

  final String label;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final color =
        overdue ? Theme.of(context).colorScheme.error : AppColors.warning;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _ProgressAction extends StatelessWidget {
  const _ProgressAction({required this.status, required this.onTap});

  final TaskStatus status;
  final VoidCallback onTap;

  IconData get _icon => switch (status) {
    TaskStatus.newTask => Icons.play_arrow_rounded,
    TaskStatus.pending => Icons.check_rounded,
    TaskStatus.completed => Icons.replay_rounded,
    TaskStatus.failed => Icons.replay_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, size: 16, color: scheme.onPrimaryContainer),
              const SizedBox(width: 4),
              Text(
                TaskWorkflow.nextActionLabelKey(status).tr(context),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
