import 'package:flutter/material.dart';
import '../../tasks/data/models/task_model.dart';
import '../../tasks/presentation/screens/completed_tasks_view.dart';
import '../../tasks/presentation/screens/failed_tasks_view.dart';
import '../../tasks/presentation/screens/new_tasks_view.dart';
import '../../tasks/presentation/screens/pending_tasks_view.dart';

/// One dashboard tab: it maps 1:1 to a task [status] and owns the page, the
/// localized label and the icon for that status.
///
/// Keeping status, page, label and icon together in one list is what stops the
/// navigation order from drifting away from the status a page renders — the
/// overview counters, the visible list and the create-action gating all read
/// the same source.
class TaskTabItem {
  const TaskTabItem({
    required this.status,
    required this.labelKey,
    required this.icon,
    required this.page,
  });

  final TaskStatus status;
  final String labelKey;
  final IconData icon;
  final Widget page;
}

const List<TaskTabItem> taskTabs = [
  TaskTabItem(
    status: TaskStatus.newTask,
    labelKey: 'new',
    icon: Icons.new_releases_rounded,
    page: NewTasksView(),
  ),
  TaskTabItem(
    status: TaskStatus.pending,
    labelKey: 'pending',
    icon: Icons.pending_actions_outlined,
    page: PendingTasksView(),
  ),
  TaskTabItem(
    status: TaskStatus.completed,
    labelKey: 'completed',
    icon: Icons.check_circle_outline_rounded,
    page: CompletedTasksView(),
  ),
  TaskTabItem(
    status: TaskStatus.failed,
    labelKey: 'failed',
    icon: Icons.error_outline_rounded,
    page: FailedTasksView(),
  ),
];

List<Widget> pages = [for (final tab in taskTabs) tab.page];
List<String> navItemsNames = [for (final tab in taskTabs) tab.labelKey];
List<IconData> navItemsIcons = [for (final tab in taskTabs) tab.icon];
