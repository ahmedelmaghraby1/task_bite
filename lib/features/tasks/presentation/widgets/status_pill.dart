import 'package:flutter/material.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/core/themes/colors.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';

/// Compact status chip used on task cards and the details screen.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final TaskStatus status;

  Color get _color => switch (status) {
    TaskStatus.newTask => AppColors.info,
    TaskStatus.pending => AppColors.warning,
    TaskStatus.completed => AppColors.success,
    TaskStatus.failed => AppColors.red,
  };

  String get _labelKey => switch (status) {
    TaskStatus.newTask => 'new',
    TaskStatus.pending => 'pending',
    TaskStatus.completed => 'completed',
    TaskStatus.failed => 'failed',
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _labelKey.tr(context),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
