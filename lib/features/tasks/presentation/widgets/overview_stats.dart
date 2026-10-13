import 'package:flutter/material.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/core/themes/colors.dart';
import 'package:taskbite/features/tasks/presentation/cubit/tasks_state.dart';

/// Five real-data stat cards: All tasks, New, In progress, Completed, Failed.
///
/// Every value is a derived getter on [TasksState], so all tasks are counted
/// exactly once and each bucket reflects only its own status.
class OverviewStats extends StatelessWidget {
  const OverviewStats({super.key, required this.state});

  final TasksState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'overview'.tr(context),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(
              labelKey: 'statTotal',
              value: state.totalCount,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            _StatCard(
              labelKey: 'statNew',
              value: state.newCount,
              color: AppColors.info,
            ),
            const SizedBox(width: 6),
            _StatCard(
              labelKey: 'statInProgress',
              value: state.pendingCount,
              color: AppColors.warning,
            ),
            const SizedBox(width: 6),
            _StatCard(
              labelKey: 'statCompleted',
              value: state.completedCount,
              color: AppColors.success,
            ),
            const SizedBox(width: 6),
            _StatCard(
              labelKey: 'statFailed',
              value: state.failedCount,
              color: AppColors.red,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.labelKey,
    required this.value,
    required this.color,
  });

  final String labelKey;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 4,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                labelKey.tr(context),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
