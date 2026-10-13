import 'package:flutter/material.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/tasks/presentation/cubit/task_composer_cubit.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_fields_view.dart';

/// Editable review of the draft produced by the AI (or the manual fallback).
///
/// The exact same [TaskFieldsView] as the manual tab is used, so validation
/// and field behaviour stay consistent between typing and voice. Nothing is
/// ever saved automatically: the user always reviews first. A failed AI call
/// keeps the transcript visible and pre-fills the draft with the user's own
/// words, so the task can still be finished without the AI service.
class DraftReviewPanel extends StatelessWidget {
  const DraftReviewPanel({
    super.key,
    required this.cubit,
    required this.titleController,
    required this.descriptionController,
    required this.dueDate,
    required this.onDueDateChanged,
    required this.onSave,
    required this.isSaving,
    required this.titleInvalid,
    required this.noticeKey,
    required this.transcript,
  });

  final TaskComposerCubit cubit;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final DateTime? dueDate;
  final ValueChanged<DateTime?> onDueDateChanged;
  final VoidCallback onSave;
  final bool isSaving;
  final bool titleInvalid;
  final String? noticeKey;
  final String? transcript;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasTranscript = transcript != null && transcript!.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'reviewDraft'.tr(context),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (hasTranscript)
              TextButton.icon(
                onPressed: isSaving ? null : cubit.regenerate,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('regenerate'.tr(context)),
              ),
          ],
        ),
        if (noticeKey != null) ...[
          const SizedBox(height: 12),
          _NoticeBanner(messageKey: noticeKey!),
        ],
        if (hasTranscript) ...[
          const SizedBox(height: 12),
          _TranscriptDisclosure(transcript: transcript!),
        ],
        const SizedBox(height: 16),
        TaskFieldsView(
          titleController: titleController,
          descriptionController: descriptionController,
          dueDate: dueDate,
          onDueDateChanged: onDueDateChanged,
          showTitleError: titleInvalid,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isSaving ? null : onSave,
            icon:
                isSaving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.check_rounded),
            label: Text('saveTask'.tr(context)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }
}

class _TranscriptDisclosure extends StatelessWidget {
  const _TranscriptDisclosure({required this.transcript});

  final String transcript;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
          leading: Icon(Icons.record_voice_over_rounded, color: scheme.primary),
          title: Text(
            'transcriptLabel'.tr(context),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                transcript,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.messageKey});

  final String messageKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: scheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              messageKey.tr(context),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onTertiaryContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
