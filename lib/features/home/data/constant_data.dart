import 'package:flutter/material.dart';
import '../../tasks/presentation/screens/completed_tasks_view.dart';
import '../../tasks/presentation/screens/new_tasks_view.dart';
import '../../tasks/presentation/screens/pending_tasks_view.dart';

List<Widget> pages = [NewTasksView(), PendingTasksView(), CompletedTasksView()];
List<String> navItemsNames = ['new', 'pending', 'completed'];
List<IconData> navItemsIcons = [
  Icons.new_releases,
  Icons.pending_actions_outlined,
  Icons.check_circle,
];
