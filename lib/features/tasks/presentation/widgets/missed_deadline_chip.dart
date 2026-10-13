import 'package:flutter/material.dart';
import 'package:taskbite/core/localization/app_localization.dart';

/// Compact, explicit "the deadline was missed" marker.
///
/// Rendered on failed task cards and on the details screen so the missed
/// deadline is visible by text as well as by the error-coloured due chip.
class MissedDeadlineChip extends StatelessWidget {
  const MissedDeadlineChip({super.key, this.compact = true});

  /// Compact sizing for list cards; the details screen uses the roomier size
  /// that matches its due-date chip.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 10 : 20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: compact ? 14 : 15,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            'missedDeadline'.tr(context),
            style: (compact ? textTheme.labelSmall : textTheme.labelMedium)
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
