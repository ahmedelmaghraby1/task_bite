import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskbite/core/audio/audio_recorder_service.dart';
import 'package:taskbite/core/injection/injection.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/core/localization/cubit/localization_cubit.dart';
import 'package:taskbite/features/ai/domain/models/task_draft.dart';
import 'package:taskbite/features/ai/domain/repositories/ai_task_repository.dart';
import 'package:taskbite/features/ai/domain/repositories/audio_transcription_repository.dart';
import 'package:taskbite/features/tasks/domain/models/stored_task.dart';
import 'package:taskbite/features/tasks/domain/repositories/task_repository.dart';
import 'package:taskbite/features/tasks/presentation/cubit/task_composer_cubit.dart';
import 'package:taskbite/features/tasks/presentation/cubit/task_composer_state.dart';
import 'package:taskbite/features/tasks/presentation/widgets/custom_alert_dialog.dart';
import 'package:taskbite/features/tasks/presentation/widgets/draft_review_panel.dart';
import 'package:taskbite/features/tasks/presentation/widgets/processing_panel.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_fields_view.dart';
import 'package:taskbite/features/tasks/presentation/widgets/voice_recording_panel.dart';

/// Opens the task composer as a modal bottom sheet.
///
/// Create and edit share this single surface. Pass [existing] to edit a task
/// (the sheet opens on the manual form pre-filled with the stored values), or
/// [initialTab] to bias the create flow towards voice or typing.
Future<void> showTaskComposer(
  BuildContext context, {
  StoredTask? existing,
  ComposerTab initialTab = ComposerTab.manual,
}) {
  final cubit = TaskComposerCubit(
    repository: getIt<TaskRepository>(),
    aiRepository: getIt<AiTaskRepository>(),
    transcriptionRepository: getIt<AudioTranscriptionRepository>(),
    recorder: getIt<AudioRecorderService>(),
    existing: existing,
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder:
        (_) => BlocProvider<TaskComposerCubit>(
          create: (_) => cubit,
          child: TaskComposerSheet(initialTab: initialTab),
        ),
  );
}

/// The composer sheet itself. Owns the text controllers for the manual form
/// and the AI draft review, so switching between Voice and Text never loses
/// what the user already typed.
class TaskComposerSheet extends StatefulWidget {
  const TaskComposerSheet({super.key, required this.initialTab});

  final ComposerTab initialTab;

  @override
  State<TaskComposerSheet> createState() => _TaskComposerSheetState();
}

class _TaskComposerSheetState extends State<TaskComposerSheet>
    with WidgetsBindingObserver {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _dueDate;
  TaskDraft? _lastSyncedDraft;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final cubit = context.read<TaskComposerCubit>();
    _syncFromDraft(cubit.state.draft);
    if (widget.initialTab != cubit.state.tab) {
      cubit.switchTab(widget.initialTab);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cubit = context.read<TaskComposerCubit>();
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        cubit.onAppPaused();
      case AppLifecycleState.resumed:
        cubit.onAppResumed();
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Copies a draft into the shared controllers. Only called when the draft
  /// actually changed (a new AI result), so late async results can never
  /// overwrite newer user edits.
  void _syncFromDraft(TaskDraft? draft) {
    if (draft == null) return;
    _lastSyncedDraft = draft;
    _titleController.text = draft.title;
    _descriptionController.text = draft.description;
    _dueDate = draft.dueDate;
    final selection = TextSelection.collapsed(offset: draft.title.length);
    _titleController.selection = selection;
  }

  Future<void> _handleClose() async {
    final cubit = context.read<TaskComposerCubit>();
    if (cubit.state.step == ComposerStep.recording) {
      final discard = await _confirmDiscard();
      if (!discard) return;
      await cubit.cancelRecording();
    }
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => CustomAlertDialog(
            message: 'discardRecordingMessage'.tr(context),
            yesTitle: 'discard'.tr(context),
            noTitle: 'keep'.tr(context),
            onYesFunction: () => Navigator.of(dialogContext).pop(true),
            onNoFunction: () => Navigator.of(dialogContext).pop(false),
          ),
    );
    return result ?? false;
  }

  Future<void> _startVoice() async {
    final cubit = context.read<TaskComposerCubit>();
    final localeId = LocalizationCubit.get(context).recordingLanguage;
    await cubit.startRecording(localeId);
  }

  Future<void> _save() async {
    final cubit = context.read<TaskComposerCubit>();
    await cubit.save(
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _dueDate,
    );
    // On success state.saved flips and the listener below closes the sheet.
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskComposerCubit, TaskComposerState>(
      listenWhen:
          (previous, next) =>
              previous.draft != next.draft || previous.saved != next.saved,
      listener: (context, state) {
        if (state.saved) {
          Navigator.of(context).maybePop(true);
          return;
        }
        if (state.draft != _lastSyncedDraft) {
          setState(() => _syncFromDraft(state.draft));
        }
      },
      child: BlocBuilder<TaskComposerCubit, TaskComposerState>(
        builder: (context, state) {
          final size = MediaQuery.sizeOf(context);
          final viewInsets = MediaQuery.viewInsetsOf(context);
          final titleKey =
              state.step == ComposerStep.review
                  ? 'review'
                  : (context.read<TaskComposerCubit>().isEditMode
                      ? 'editTask'
                      : 'addTask');
          return Padding(
            padding: EdgeInsets.only(bottom: viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: size.height * 0.92),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetHeader(
                    titleKey: titleKey,
                    subtitleKey: _subtitleKeyFor(state.step),
                    onClose: _handleClose,
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        20,
                        4,
                        20,
                        20,
                      ),
                      child: _buildStep(state),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _subtitleKeyFor(ComposerStep step) {
    switch (step) {
      case ComposerStep.recording:
        return 'recordingHint';
      case ComposerStep.processing:
        return 'processingMessage';
      case ComposerStep.review:
        return 'reviewDraft';
      case ComposerStep.compose:
        return null;
    }
  }

  Widget _buildStep(TaskComposerState state) {
    switch (state.step) {
      case ComposerStep.recording:
        return VoiceRecordingPanel(cubit: context.read<TaskComposerCubit>());
      case ComposerStep.processing:
        return ProcessingPanel(cubit: context.read<TaskComposerCubit>());
      case ComposerStep.review:
        return DraftReviewPanel(
          cubit: context.read<TaskComposerCubit>(),
          titleController: _titleController,
          descriptionController: _descriptionController,
          dueDate: _dueDate,
          onDueDateChanged: (date) => setState(() => _dueDate = date),
          onSave: _save,
          isSaving: state.isSaving,
          titleInvalid: state.titleInvalid,
          noticeKey: state.noticeKey,
          transcript: state.transcript,
        );
      case ComposerStep.compose:
        return _buildCompose(state);
    }
  }

  Widget _buildCompose(TaskComposerState state) {
    final cubit = context.read<TaskComposerCubit>();
    final noticeKey = state.noticeKey;
    if (cubit.isEditMode) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (noticeKey != null) ...[
            _InlineNotice(messageKey: noticeKey),
            const SizedBox(height: 14),
          ],
          TaskFieldsView(
            titleController: _titleController,
            descriptionController: _descriptionController,
            dueDate: _dueDate,
            onDueDateChanged: (date) => setState(() => _dueDate = date),
            showTitleError: state.titleInvalid,
          ),
          const SizedBox(height: 20),
          _SaveButton(isSaving: state.isSaving, onSave: _save),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<ComposerTab>(
          segments: [
            ButtonSegment<ComposerTab>(
              value: ComposerTab.voice,
              icon: const Icon(Icons.mic_rounded, size: 18),
              label: Text('voiceInput'.tr(context)),
            ),
            ButtonSegment<ComposerTab>(
              value: ComposerTab.manual,
              icon: const Icon(Icons.keyboard_rounded, size: 18),
              label: Text('textInput'.tr(context)),
            ),
          ],
          selected: {state.tab},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => cubit.switchTab(selection.first),
        ),
        const SizedBox(height: 18),
        if (noticeKey != null) ...[
          _InlineNotice(messageKey: noticeKey),
          const SizedBox(height: 14),
        ],
        if (state.tab == ComposerTab.voice)
          _VoiceIntro(isStarting: false, onStart: _startVoice)
        else ...[
          TaskFieldsView(
            titleController: _titleController,
            descriptionController: _descriptionController,
            dueDate: _dueDate,
            onDueDateChanged: (date) => setState(() => _dueDate = date),
            showTitleError: state.titleInvalid,
          ),
          const SizedBox(height: 20),
          _SaveButton(isSaving: state.isSaving, onSave: _save),
        ],
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onSave});

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }
}

class _VoiceIntro extends StatelessWidget {
  const _VoiceIntro({required this.isStarting, required this.onStart});

  final bool isStarting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'startRecording'.tr(context),
          child: Material(
            color: scheme.primaryContainer,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isStarting ? null : onStart,
              child: SizedBox(
                width: 96,
                height: 96,
                child: Icon(
                  Icons.mic_rounded,
                  size: 44,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'recordingHint'.tr(context),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isStarting ? null : onStart,
            icon: const Icon(Icons.mic_rounded),
            label: Text('startRecording'.tr(context)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.messageKey});

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

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.titleKey,
    required this.subtitleKey,
    required this.onClose,
  });

  final String titleKey;
  final String? subtitleKey;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleKey.tr(context),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (subtitleKey != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitleKey!.tr(context),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'close'.tr(context),
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
