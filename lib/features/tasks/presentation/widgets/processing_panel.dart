import 'package:flutter/material.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/tasks/presentation/cubit/task_composer_cubit.dart';
import 'package:taskbite/features/tasks/presentation/cubit/task_composer_state.dart';

/// Shown while the transcript is being converted into a structured draft.
///
/// The user is never blocked: "Edit manually" cancels the in-flight request
/// (stale responses are dropped by the cubit's generation guard) and opens the
/// editable draft immediately with the transcript preserved.
class ProcessingPanel extends StatelessWidget {
  const ProcessingPanel({super.key, required this.cubit});

  final TaskComposerCubit cubit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final transcript = cubit.state.transcript?.trim() ?? '';
    final messageKey =
        cubit.state.processingStage == ComposerProcessingStage.transcribing
            ? 'transcribingMessage'
            : 'generatingTaskMessage';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 62,
            height: 62,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: scheme.primary,
              backgroundColor: scheme.primaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          messageKey.tr(context),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 18),
        if (transcript.isNotEmpty)
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '“$transcript”',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: cubit.skipAiAndEditManually,
          icon: const Icon(Icons.edit_note_rounded),
          label: Text('editManually'.tr(context)),
        ),
      ],
    );
  }
}
