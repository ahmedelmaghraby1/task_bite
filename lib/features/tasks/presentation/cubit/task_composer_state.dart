import 'package:flutter/foundation.dart';
import 'package:taskbite/features/ai/domain/models/task_draft.dart';
import 'package:taskbite/features/ai/domain/repositories/ai_task_repository.dart';

enum ComposerTab { manual, voice }

enum ComposerStep { compose, recording, processing, review }

/// Which AI stage is running while [ComposerStep.processing] is active.
enum ComposerProcessingStage { transcribing, generating }

@immutable
class TaskComposerState {
  const TaskComposerState({
    this.tab = ComposerTab.manual,
    this.step = ComposerStep.compose,
    this.transcript,
    this.draft,
    this.isSaving = false,
    this.noticeKey,
    this.aiErrorKind,
    this.titleInvalid = false,
    this.saved = false,
    this.recordingElapsed = Duration.zero,
    this.amplitudeAvailable = true,
    this.processingStage = ComposerProcessingStage.transcribing,
  });

  final ComposerTab tab;
  final ComposerStep step;

  /// The final recognized transcript of the latest recording.
  final String? transcript;

  /// The editable draft produced by AI (or the manual fallback draft).
  final TaskDraft? draft;

  final bool isSaving;

  /// Localization key for an inline notice (AI unavailable, empty transcript,
  /// recorder failure, save failure, ...). Rendered above the actions.
  final String? noticeKey;

  final AiTaskErrorKind? aiErrorKind;

  /// Set when the user tried to save with an empty title.
  final bool titleInvalid;

  /// Set once a task has been persisted; the sheet closes on this.
  final bool saved;

  /// Elapsed time of the active recording session, in state so the timer text
  /// rebuilds every tick.
  final Duration recordingElapsed;

  /// Whether real microphone amplitude is available for the waveform. When
  /// `false` the UI shows an honest fallback instead of a fake animation.
  final bool amplitudeAvailable;

  /// Which AI stage is running during [ComposerStep.processing].
  final ComposerProcessingStage processingStage;

  TaskComposerState copyWith({
    ComposerTab? tab,
    ComposerStep? step,
    String? transcript,
    bool clearTranscript = false,
    TaskDraft? draft,
    bool clearDraft = false,
    bool? isSaving,
    String? noticeKey,
    bool clearNotice = false,
    AiTaskErrorKind? aiErrorKind,
    bool clearAiError = false,
    bool? titleInvalid,
    bool? saved,
    Duration? recordingElapsed,
    bool? amplitudeAvailable,
    ComposerProcessingStage? processingStage,
  }) {
    return TaskComposerState(
      tab: tab ?? this.tab,
      step: step ?? this.step,
      transcript: clearTranscript ? null : (transcript ?? this.transcript),
      draft: clearDraft ? null : (draft ?? this.draft),
      isSaving: isSaving ?? this.isSaving,
      noticeKey: clearNotice ? null : (noticeKey ?? this.noticeKey),
      aiErrorKind: clearAiError ? null : (aiErrorKind ?? this.aiErrorKind),
      titleInvalid: titleInvalid ?? this.titleInvalid,
      saved: saved ?? this.saved,
      recordingElapsed: recordingElapsed ?? this.recordingElapsed,
      amplitudeAvailable: amplitudeAvailable ?? this.amplitudeAvailable,
      processingStage: processingStage ?? this.processingStage,
    );
  }

  @override
  String toString() =>
      'TaskComposerState($tab, $step, recording=${recordingElapsed.inSeconds}s, '
      'notice=$noticeKey, saved=$saved)';
}
