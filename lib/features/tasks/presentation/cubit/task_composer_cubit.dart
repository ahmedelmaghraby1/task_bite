import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskbite/core/audio/audio_recorder_service.dart';
import 'package:taskbite/core/audio/recording_validation.dart';
import 'package:taskbite/features/ai/domain/models/ai_task_request.dart';
import 'package:taskbite/features/ai/domain/models/task_draft.dart';
import 'package:taskbite/features/ai/domain/repositories/ai_task_repository.dart';
import 'package:taskbite/features/ai/domain/repositories/audio_transcription_repository.dart';
import 'package:taskbite/features/ai/domain/text/bullet_text.dart';
import 'package:taskbite/features/tasks/domain/models/stored_task.dart';
import 'package:taskbite/features/tasks/domain/repositories/task_repository.dart';
import 'package:taskbite/features/tasks/presentation/cubit/task_composer_state.dart';

/// Drives the full create/edit flow inside the composer sheet:
///
/// * **compose** – pick Voice or Type input; Type shows the manual form.
/// * **recording** – capture microphone audio to a temp file. The timer and
///   waveform are driven by the real recorder (see [AudioRecorderService]).
/// * **processing** – Stage A transcribes the audio, Stage B turns the
///   transcript into a structured draft. Each stage is invalidated by a
///   generation token so a late result can never overwrite newer state.
/// * **review** – the draft is editable before saving. Nothing is persisted
///   until the user confirms.
///
/// A configuration error is surfaced *before* recording starts so the user is
/// never left recording into a pipeline that cannot process it. The recorded
/// temp file is always cleaned up once it is no longer needed.
class TaskComposerCubit extends Cubit<TaskComposerState> {
  TaskComposerCubit({
    required TaskRepository repository,
    required AiTaskRepository aiRepository,
    required AudioTranscriptionRepository transcriptionRepository,
    required AudioRecorderService recorder,
    StoredTask? existing,
  }) : _repository = repository,
       _aiRepository = aiRepository,
       _transcriptionRepository = transcriptionRepository,
       _recorder = recorder,
       _existing = existing,
       super(TaskComposerState()) {
    if (_existing != null) {
      emit(
        state.copyWith(
          tab: ComposerTab.manual,
          step: ComposerStep.compose,
          draft: TaskDraft(
            title: _existing.task.title,
            description: _existing.task.content,
            dueDate: _existing.task.dueDate,
          ),
        ),
      );
    }
  }

  final TaskRepository _repository;
  final AiTaskRepository _aiRepository;
  final AudioTranscriptionRepository _transcriptionRepository;
  final AudioRecorderService _recorder;
  final StoredTask? _existing;

  String? _languageHint;
  Timer? _timer;
  int _generation = 0;
  bool _isProcessing = false;

  bool get isEditMode => _existing != null;
  Duration get elapsedTime => state.recordingElapsed;

  /// Live microphone level for the waveform (driven by the recorder).
  ValueListenable<double> get inputLevel => _recorder.inputLevel;

  /// Whether the recorder can report amplitude on this platform/session.
  bool get isAmplitudeAvailable =>
      _recorder.isAmplitudeAvailable && state.amplitudeAvailable;

  void switchTab(ComposerTab tab) {
    if (isClosed) return;
    // Never leave a live recording because the user tapped the other tab.
    if (state.step == ComposerStep.recording) return;
    emit(state.copyWith(tab: tab, noticeKey: null, titleInvalid: false));
  }

  /// Starts a brand-new recording session. Duplicate starts are ignored.
  ///
  /// The AI endpoints are validated first: recording audio that cannot be
  /// transcribed would only waste the user's words.
  Future<void> startRecording(String localeId) async {
    if (isClosed || state.step == ComposerStep.recording) return;
    _languageHint = localeId;

    if (!_transcriptionRepository.isConfigured || !_aiRepository.isConfigured) {
      if (!isClosed) {
        emit(
          state.copyWith(
            tab: ComposerTab.voice,
            step: ComposerStep.compose,
            noticeKey: 'aiNotConfiguredMessage',
            clearDraft: true,
            clearTranscript: true,
          ),
        );
      }
      return;
    }

    try {
      await _recorder.startRecording();
    } on AudioRecorderException catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            tab: ComposerTab.voice,
            step: ComposerStep.compose,
            noticeKey:
                e.kind == AudioRecorderErrorKind.permissionDenied
                    ? 'micPermissionDeniedMessage'
                    : 'recorderStartFailedMessage',
            clearDraft: true,
            clearTranscript: true,
          ),
        );
      }
      return;
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            tab: ComposerTab.voice,
            step: ComposerStep.compose,
            noticeKey: 'recorderStartFailedMessage',
            clearDraft: true,
            clearTranscript: true,
          ),
        );
      }
      return;
    }

    _startTimer();

    if (!isClosed) {
      emit(
        state.copyWith(
          tab: ComposerTab.voice,
          step: ComposerStep.recording,
          clearTranscript: true,
          clearDraft: true,
          clearNotice: true,
          clearAiError: true,
          titleInvalid: false,
          recordingElapsed: Duration.zero,
          amplitudeAvailable: _recorder.isAmplitudeAvailable,
        ),
      );
    }
  }

  Future<void> finishRecording() async {
    if (_isProcessing || state.step != ComposerStep.recording) return;
    _isProcessing = true;
    try {
      _timer?.cancel();
      final recorded = await _recorder.stopRecording();

      if (recorded == null) {
        await _failRecording(RecordingProblem.missing);
        return;
      }

      final file = File(recorded.path);
      final exists = await file.exists();
      final length = exists ? await file.length() : 0;
      final problem = classifyRecording(
        exists: exists,
        lengthInBytes: length,
        path: recorded.path,
      );
      if (problem != null) {
        await _failRecording(problem);
        return;
      }

      if (!isClosed) {
        emit(
          state.copyWith(
            step: ComposerStep.processing,
            processingStage: ComposerProcessingStage.transcribing,
            clearNotice: true,
            clearAiError: true,
          ),
        );
      }
      await _transcribeAndGenerate(file);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> cancelRecording() async {
    if (_isProcessing) return;
    _timer?.cancel();
    await _recorder.cancelRecording();
    if (!isClosed) {
      emit(
        state.copyWith(
          step: ComposerStep.compose,
          tab: ComposerTab.voice,
          clearTranscript: true,
          clearDraft: true,
          clearNotice: true,
          clearAiError: true,
          recordingElapsed: Duration.zero,
        ),
      );
    }
  }

  /// Cancels an in-flight request and opens the editable manual fallback when a
  /// transcript exists, otherwise returns to the start of the voice tab.
  void skipAiAndEditManually() {
    _generation++;
    final transcript = state.transcript;
    if (transcript != null && transcript.trim().isNotEmpty) {
      if (!isClosed) {
        emit(
          state.copyWith(
            step: ComposerStep.review,
            draft: _fallbackDraft(transcript),
            clearNotice: true,
            clearAiError: true,
          ),
        );
      }
      return;
    }
    unawaited(_recorder.cleanUp());
    if (!isClosed) {
      emit(
        state.copyWith(
          step: ComposerStep.compose,
          tab: ComposerTab.voice,
          clearDraft: true,
          clearNotice: true,
          clearAiError: true,
        ),
      );
    }
  }

  /// Regenerates the draft from the stored transcript (no new recording needed).
  void regenerate() {
    final transcript = state.transcript?.trim();
    if (transcript == null || transcript.isEmpty) return;
    if (isClosed || state.step == ComposerStep.processing) return;
    emit(
      state.copyWith(
        step: ComposerStep.processing,
        processingStage: ComposerProcessingStage.generating,
        clearNotice: true,
        clearAiError: true,
      ),
    );
    unawaited(_regenerateDraft(transcript));
  }

  /// Persists a task (create or update). Returns true only when saved.
  Future<bool> save({
    required String title,
    required String description,
    DateTime? dueDate,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      if (!isClosed) emit(state.copyWith(titleInvalid: true, isSaving: false));
      return false;
    }
    if (isClosed) return false;

    if (!isClosed) {
      emit(
        state.copyWith(isSaving: true, titleInvalid: false, clearNotice: true),
      );
    }
    try {
      if (_existing != null) {
        await _repository.updateTask(
          key: _existing.key,
          title: trimmedTitle,
          content: description.trim(),
          dueDate: dueDate,
        );
      } else {
        await _repository.createTask(
          title: trimmedTitle,
          content: description.trim(),
          dueDate: dueDate,
        );
      }
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, saved: true));
      }
      return true;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, noticeKey: 'saveFailedMessage'));
      }
      return false;
    }
  }

  Future<void> onAppPaused() async {
    // The recording is intentionally left running: the user decides when to
    // finish. Nothing relies on a background timer to complete the session.
  }

  Future<void> onAppResumed() async {
    // No-op
  }

  // ---- Internals ----------------------------------------------------------

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (isClosed) return;
      final elapsed = _recorder.elapsed;
      if (elapsed == state.recordingElapsed &&
          state.amplitudeAvailable == _recorder.isAmplitudeAvailable) {
        return;
      }
      emit(
        state.copyWith(
          recordingElapsed: elapsed,
          amplitudeAvailable: _recorder.isAmplitudeAvailable,
        ),
      );
    });
  }

  Future<void> _failRecording(RecordingProblem problem) async {
    await _recorder.cleanUp();
    if (isClosed) return;
    emit(
      state.copyWith(
        step: ComposerStep.compose,
        tab: ComposerTab.voice,
        noticeKey: switch (problem) {
          RecordingProblem.missing ||
          RecordingProblem.empty => 'noAudioCapturedMessage',
          RecordingProblem.unsupportedFormat => 'unsupportedAudioMessage',
          RecordingProblem.tooLarge => 'audioTooLargeMessage',
        },
        clearTranscript: true,
        clearDraft: true,
        clearAiError: true,
        recordingElapsed: Duration.zero,
      ),
    );
  }

  Future<void> _transcribeAndGenerate(File file) async {
    final generation = ++_generation;

    final String transcript;
    try {
      final raw = await _transcriptionRepository.transcribe(
        audioFile: file,
        languageHint: _languageHint,
      );
      transcript = raw.trim();
    } on AiTaskException catch (e) {
      await _handleStageFailure(generation, e);
      return;
    } catch (_) {
      await _handleStageFailure(
        generation,
        const AiTaskException(
          AiTaskErrorKind.network,
          'Transcription failed unexpectedly.',
        ),
      );
      return;
    }
    if (generation != _generation || isClosed) return;

    if (transcript.isEmpty) {
      await _recorder.cleanUp();
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          step: ComposerStep.compose,
          tab: ComposerTab.voice,
          noticeKey: 'emptyTranscriptMessage',
          clearDraft: true,
          clearTranscript: true,
          recordingElapsed: Duration.zero,
        ),
      );
      return;
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          step: ComposerStep.processing,
          processingStage: ComposerProcessingStage.generating,
          transcript: transcript,
        ),
      );
    }

    try {
      final draft = await _aiRepository.generateTaskDraft(
        AiTaskRequest(transcript: transcript, languageHint: _languageHint),
      );
      if (generation != _generation || isClosed) return;
      await _recorder.cleanUp();
      emit(
        state.copyWith(
          step: ComposerStep.review,
          transcript: transcript,
          draft: draft,
          clearNotice: true,
          clearAiError: true,
        ),
      );
    } on AiTaskException catch (e) {
      await _recorder.cleanUp();
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          step: ComposerStep.review,
          transcript: transcript,
          draft: _fallbackDraft(transcript),
          noticeKey: _messageKeyForAiError(e.kind),
          aiErrorKind: e.kind,
        ),
      );
    } catch (_) {
      await _recorder.cleanUp();
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          step: ComposerStep.review,
          transcript: transcript,
          draft: _fallbackDraft(transcript),
          noticeKey: 'aiNetworkMessage',
          aiErrorKind: AiTaskErrorKind.network,
        ),
      );
    }
  }

  Future<void> _regenerateDraft(String transcript) async {
    final generation = ++_generation;
    try {
      final draft = await _aiRepository.generateTaskDraft(
        AiTaskRequest(transcript: transcript, languageHint: _languageHint),
      );
      if (generation != _generation || isClosed) return;
      emit(
        state.copyWith(
          step: ComposerStep.review,
          transcript: transcript,
          draft: draft,
          clearNotice: true,
          clearAiError: true,
        ),
      );
    } on AiTaskException catch (e) {
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          step: ComposerStep.review,
          transcript: transcript,
          draft: _fallbackDraft(transcript),
          noticeKey: _messageKeyForAiError(e.kind),
          aiErrorKind: e.kind,
        ),
      );
    } catch (_) {
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          step: ComposerStep.review,
          transcript: transcript,
          draft: _fallbackDraft(transcript),
          noticeKey: 'aiNetworkMessage',
          aiErrorKind: AiTaskErrorKind.network,
        ),
      );
    }
  }

  /// First-stage failures return the user to the voice start so they can retry,
  /// with a distinct message from second-stage failures.
  Future<void> _handleStageFailure(
    int generation,
    AiTaskException error,
  ) async {
    await _recorder.cleanUp();
    if (isClosed || generation != _generation) return;
    emit(
      state.copyWith(
        step: ComposerStep.compose,
        tab: ComposerTab.voice,
        noticeKey:
            error.kind == AiTaskErrorKind.notConfigured
                ? 'aiNotConfiguredMessage'
                : 'transcriptionFailedMessage',
        aiErrorKind: error.kind,
        clearDraft: true,
        clearTranscript: true,
        recordingElapsed: Duration.zero,
      ),
    );
  }

  TaskDraft _fallbackDraft(String transcript) {
    final trimmed = transcript.trim();
    final bullets = normalizeToBulletPoints(trimmed);
    return TaskDraft(
      title: _suggestTitle(trimmed),
      description: bullets.isEmpty ? trimmed : bullets,
      dueDate: null,
      sourceTranscript: trimmed,
    );
  }

  /// Mechanical, intent-preserving title suggestion from the user's own words
  /// (used only as an editable fallback when AI is unavailable).
  static String _suggestTitle(String transcript) {
    const maxLength = 60;
    final sentenceEnd = transcript.indexOf(RegExp('[.!?\\n؛؟]'));
    var candidate =
        sentenceEnd >= 0 ? transcript.substring(0, sentenceEnd).trim() : '';
    if (candidate.isEmpty) {
      candidate = transcript.split(RegExp(r'\s+')).take(8).join(' ');
    }
    if (candidate.length <= maxLength) return candidate;
    return '${candidate.substring(0, maxLength - 1).trimRight()}…';
  }

  String _messageKeyForAiError(AiTaskErrorKind kind) {
    switch (kind) {
      case AiTaskErrorKind.notConfigured:
        return 'aiNotConfiguredMessage';
      case AiTaskErrorKind.network:
        return 'aiNetworkMessage';
      case AiTaskErrorKind.timeout:
        return 'aiTimeoutMessage';
      case AiTaskErrorKind.unauthorized:
        return 'aiAuthMessage';
      case AiTaskErrorKind.rateLimited:
        return 'aiRateLimitedMessage';
      case AiTaskErrorKind.serverError:
        return 'aiServerErrorMessage';
      case AiTaskErrorKind.invalidResponse:
        return 'aiInvalidResponseMessage';
    }
  }

  @override
  Future<void> close() async {
    _generation++;
    _timer?.cancel();
    await _recorder.dispose();
    return super.close();
  }
}
