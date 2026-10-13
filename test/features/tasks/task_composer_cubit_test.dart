import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskbite/core/audio/audio_recorder_service.dart';
import 'package:taskbite/features/ai/domain/models/task_draft.dart';
import 'package:taskbite/features/ai/domain/repositories/ai_task_repository.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/domain/models/stored_task.dart';
import 'package:taskbite/features/tasks/presentation/cubit/task_composer_cubit.dart';
import 'package:taskbite/features/tasks/presentation/cubit/task_composer_state.dart';

import '../../support/fakes.dart';

Future<void> _settle([int ms = 10]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

/// Test double for the platform recorder. It writes a real file to the system
/// temp directory so the cubit's existence/size/format validation is exercised
/// against actual filesystem facts rather than a stubbed boolean.
class FakeAudioRecorderService implements AudioRecorderService {
  FakeAudioRecorderService({
    this.path,
    this.fileBytes = 2048,
    this.extension = '.m4a',
    this.createFile = true,
    this.startError,
    this.denied = false,
    this.amplitudeAvailable = true,
  });

  final String? path;
  final int fileBytes;
  final String extension;
  final bool createFile;
  final Object? startError;
  final bool denied;
  final bool amplitudeAvailable;

  final Stopwatch _watch = Stopwatch();
  final ValueNotifier<double> _level = ValueNotifier<double>(0);

  String? _path;
  bool _recording = false;

  int startCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;
  int cleanUpCalls = 0;

  @override
  bool get isRecording => _recording;

  @override
  String? get recordedFilePath => _path;

  @override
  Duration get elapsed => _watch.elapsed;

  @override
  ValueListenable<double> get inputLevel => _level;

  @override
  bool get isAmplitudeAvailable => amplitudeAvailable;

  @override
  Future<bool> hasPermission() async => !denied;

  @override
  Future<void> startRecording() async {
    if (startError != null) throw startError!;
    if (denied) {
      throw const AudioRecorderException(
        AudioRecorderErrorKind.permissionDenied,
        'denied',
      );
    }
    startCalls++;
    _recording = true;
    _watch
      ..reset()
      ..start();
    if (createFile) {
      final dir = await Directory.systemTemp.createTemp('taskbite_rec');
      final file = File('${dir.path}${Platform.pathSeparator}voice$extension');
      await file.writeAsBytes(List<int>.filled(fileBytes, 7));
      _path = file.path;
    } else {
      _path = path;
    }
  }

  @override
  Future<RecordedAudio?> stopRecording() async {
    stopCalls++;
    if (!_recording) return null;
    _recording = false;
    _watch.stop();
    final resolved = _path;
    if (resolved == null) return null;
    final file = File(resolved);
    final exists = await file.exists();
    final size = exists ? await file.length() : 0;
    return RecordedAudio(
      path: resolved,
      duration: _watch.elapsed,
      sizeInBytes: size,
    );
  }

  @override
  Future<void> cancelRecording() async {
    cancelCalls++;
    _recording = false;
    _watch.stop();
    await cleanUp();
  }

  @override
  Future<void> cleanUp() async {
    cleanUpCalls++;
    final resolved = _path;
    _path = null;
    if (resolved == null) return;
    final file = File(resolved);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> dispose() async {
    _recording = false;
    _watch.stop();
    _level.dispose();
  }
}

void main() {
  group('TaskComposerCubit', () {
    late FakeTaskRepository repository;

    tearDown(() async {
      await repository.dispose();
    });

    TaskComposerCubit build({
      FakeAiTaskRepository? ai,
      FakeAudioTranscriptionRepository? transcription,
      FakeAudioRecorderService? recorder,
      StoredTask? existing,
    }) {
      repository = FakeTaskRepository(existing == null ? null : [existing]);
      final cubit = TaskComposerCubit(
        repository: repository,
        aiRepository: ai ?? FakeAiTaskRepository(),
        transcriptionRepository:
            transcription ?? FakeAudioTranscriptionRepository(),
        recorder: recorder ?? FakeAudioRecorderService(),
        existing: existing,
      );
      addTearDown(cubit.close);
      return cubit;
    }

    group('editing mode', () {
      test('seeds the form from the existing task', () {
        final existing = StoredTask(
          key: 7,
          task: TaskModel(
            title: 'Old title',
            content: 'Old body',
            dueDate: DateTime(2026, 1, 1),
          ),
        );
        final cubit = build(existing: existing);

        expect(cubit.isEditMode, isTrue);
        expect(cubit.state.step, ComposerStep.compose);
        expect(cubit.state.tab, ComposerTab.manual);
        expect(cubit.state.draft!.title, 'Old title');
        expect(cubit.state.draft!.description, 'Old body');
        expect(cubit.state.draft!.dueDate, DateTime(2026, 1, 1));
      });

      test('save updates the stored task and marks saved', () async {
        final existing = StoredTask(
          key: 9,
          task: TaskModel(title: 'T', content: 'C'),
        );
        final cubit = build(existing: existing);

        final ok = await cubit.save(title: 'Updated', description: 'New body');
        expect(ok, isTrue);
        expect(cubit.state.saved, isTrue);
        expect(repository.updateCalls, 1);
        expect(repository.items.isNotEmpty, isTrue);
        expect(repository.items[0].task.title, 'Updated');
        expect(repository.items[0].task.content, 'New body');
      });

      test('does not change status when editing', () async {
        final existing = StoredTask(
          key: 10,
          task: TaskModel(
            title: 'T',
            content: 'C',
            status: TaskStatus.completed,
          ),
        );
        final cubit = build(existing: existing);

        await cubit.save(title: 'T2', description: 'C2');
        expect(repository.items.isNotEmpty, isTrue);
        expect(repository.items[0].task.status, TaskStatus.completed);
      });
    });

    group('manual tab', () {
      test('creates a new task when saving', () async {
        final cubit = build();
        final ok = await cubit.save(
          title: 'Write specs',
          description: 'Detail the flow',
          dueDate: DateTime(2026, 10, 14),
        );

        expect(ok, isTrue);
        expect(repository.createCalls, 1);
        expect(repository.items.length, 1);
        expect(repository.items[0].task.title, 'Write specs');
        expect(repository.items[0].task.dueDate, DateTime(2026, 10, 14));
      });

      test('rejects saving with an empty title', () async {
        final cubit = build();
        final ok = await cubit.save(title: '   ', description: 'Body');

        expect(ok, isFalse);
        expect(cubit.state.titleInvalid, isTrue);
        expect(repository.createCalls, 0);
      });
    });

    group('recording lifecycle', () {
      test('enters the recording step with a zeroed timer', () async {
        final recorder = FakeAudioRecorderService();
        final cubit = build(recorder: recorder);

        await cubit.startRecording('en');

        expect(cubit.state.step, ComposerStep.recording);
        expect(cubit.state.tab, ComposerTab.voice);
        expect(recorder.startCalls, 1);
        await cubit.cancelRecording();
      });

      test('the timer advances while recording', () async {
        final cubit = build();
        await cubit.startRecording('en');
        expect(cubit.state.recordingElapsed, Duration.zero);

        await Future<void>.delayed(const Duration(milliseconds: 450));

        // This is the regression guard for the broken timer: a same-instance
        // emit used to leave the clock stuck at 00:00 forever.
        expect(cubit.state.recordingElapsed.inMilliseconds, greaterThan(0));
        await cubit.cancelRecording();
      });

      test('ignores a duplicate start while already recording', () async {
        final recorder = FakeAudioRecorderService();
        final cubit = build(recorder: recorder);

        await cubit.startRecording('en');
        await cubit.startRecording('en');

        expect(recorder.startCalls, 1);
        await cubit.cancelRecording();
      });

      test('cancelling stops the session and clears the timer', () async {
        final cubit = build();
        await cubit.startRecording('en');
        await cubit.cancelRecording();

        expect(cubit.state.step, ComposerStep.compose);
        expect(cubit.state.recordingElapsed, Duration.zero);
      });

      test('reports denied microphone permission without recording', () async {
        final recorder = FakeAudioRecorderService(denied: true);
        final cubit = build(recorder: recorder);

        await cubit.startRecording('en');

        expect(cubit.state.step, ComposerStep.compose);
        expect(cubit.state.noticeKey, 'micPermissionDeniedMessage');
        expect(recorder.startCalls, 0);
      });

      test('reports a start failure from the recorder', () async {
        final recorder = FakeAudioRecorderService(
          startError: const AudioRecorderException(
            AudioRecorderErrorKind.startFailed,
            'boom',
          ),
        );
        final cubit = build(recorder: recorder);

        await cubit.startRecording('en');

        expect(cubit.state.step, ComposerStep.compose);
        expect(cubit.state.noticeKey, 'recorderStartFailedMessage');
      });

      test('refuses to record when the pipeline is not configured', () async {
        final recorder = FakeAudioRecorderService();
        final cubit = build(
          recorder: recorder,
          transcription: FakeAudioTranscriptionRepository(isConfigured: false),
        );

        await cubit.startRecording('en');

        expect(recorder.startCalls, 0);
        expect(cubit.state.step, ComposerStep.compose);
        expect(cubit.state.noticeKey, 'aiNotConfiguredMessage');
      });
    });

    group('two-stage AI processing', () {
      test('transcribes then generates a draft from the transcript', () async {
        final transcription = FakeAudioTranscriptionRepository(
          result: 'update the app by Thursday',
        );
        final ai = FakeAiTaskRepository(
          result: const TaskDraft(
            title: 'Update the app',
            description: '- Update the app',
          ),
        );
        final cubit = build(transcription: transcription, ai: ai);

        await cubit.startRecording('en');
        await cubit.finishRecording();
        await _settle();

        expect(transcription.calls, 1);
        expect(ai.calls, 1);
        expect(ai.requestedTranscripts.single, 'update the app by Thursday');
        expect(cubit.state.step, ComposerStep.review);
        expect(cubit.state.transcript, 'update the app by Thursday');
        expect(cubit.state.draft?.title, 'Update the app');
      });

      test('passes the language hint to transcription', () async {
        final transcription = FakeAudioTranscriptionRepository();
        final cubit = build(transcription: transcription);

        await cubit.startRecording('ar');
        await cubit.finishRecording();
        await _settle();

        expect(transcription.lastLanguageHint, 'ar');
      });

      test('rejects an empty recording without uploading', () async {
        final transcription = FakeAudioTranscriptionRepository();
        final recorder = FakeAudioRecorderService(fileBytes: 0);
        final cubit = build(transcription: transcription, recorder: recorder);

        await cubit.startRecording('en');
        await cubit.finishRecording();
        await _settle();

        expect(transcription.calls, 0);
        expect(cubit.state.step, ComposerStep.compose);
        expect(cubit.state.noticeKey, 'noAudioCapturedMessage');
        expect(recorder.cleanUpCalls, greaterThan(0));
      });

      test('rejects a missing recording file', () async {
        final recorder = FakeAudioRecorderService(
          createFile: false,
          path: 'missing_recording.m4a',
        );
        final cubit = build(recorder: recorder);

        await cubit.startRecording('en');
        await cubit.finishRecording();
        await _settle();

        expect(cubit.state.step, ComposerStep.compose);
        expect(cubit.state.noticeKey, 'noAudioCapturedMessage');
      });

      test('stops before generation when the transcript is empty', () async {
        final transcription = FakeAudioTranscriptionRepository(result: '   ');
        final ai = FakeAiTaskRepository();
        final cubit = build(transcription: transcription, ai: ai);

        await cubit.startRecording('en');
        await cubit.finishRecording();
        await _settle();

        expect(transcription.calls, 1);
        expect(ai.calls, 0);
        expect(cubit.state.step, ComposerStep.compose);
        expect(cubit.state.noticeKey, 'emptyTranscriptMessage');
      });

      test('surfaces a transcription failure and skips generation', () async {
        final transcription = FakeAudioTranscriptionRepository();
        transcription.error = const AiTaskException(
          AiTaskErrorKind.network,
          'offline',
        );
        final ai = FakeAiTaskRepository();
        final cubit = build(transcription: transcription, ai: ai);

        await cubit.startRecording('en');
        await cubit.finishRecording();
        await _settle();

        expect(ai.calls, 0);
        expect(cubit.state.step, ComposerStep.compose);
        expect(cubit.state.noticeKey, 'transcriptionFailedMessage');
        expect(cubit.state.aiErrorKind, AiTaskErrorKind.network);
      });

      test('keeps the transcript editable when generation fails', () async {
        final transcription = FakeAudioTranscriptionRepository(
          result: 'call the plumber and confirm Saturday',
        );
        final ai = FakeAiTaskRepository();
        ai.error = const AiTaskException(AiTaskErrorKind.serverError, 'boom');
        final cubit = build(transcription: transcription, ai: ai);

        await cubit.startRecording('en');
        await cubit.finishRecording();
        await _settle();

        expect(cubit.state.step, ComposerStep.review);
        expect(cubit.state.noticeKey, 'aiServerErrorMessage');
        expect(cubit.state.transcript, 'call the plumber and confirm Saturday');
        expect(cubit.state.draft, isNotNull);
        expect(cubit.state.draft!.description, startsWith('- '));
      });

      test(
        'regenerate reuses the transcript without a new recording',
        () async {
          final transcription = FakeAudioTranscriptionRepository(
            result: 'renew the passport',
          );
          final ai = FakeAiTaskRepository();
          ai.error = const AiTaskException(AiTaskErrorKind.timeout, 'slow');
          final cubit = build(transcription: transcription, ai: ai);

          await cubit.startRecording('en');
          await cubit.finishRecording();
          await _settle();
          expect(cubit.state.step, ComposerStep.review);

          ai.error = null;
          ai.result = const TaskDraft(
            title: 'Renew the passport',
            description: '- Renew the passport',
          );
          cubit.regenerate();
          await _settle();

          expect(
            transcription.calls,
            1,
            reason: 'no new recording/transcription',
          );
          expect(ai.calls, 2);
          expect(cubit.state.step, ComposerStep.review);
          expect(cubit.state.draft?.title, 'Renew the passport');
        },
      );

      test('deletes the temp recording after success', () async {
        final recorder = FakeAudioRecorderService();
        final cubit = build(recorder: recorder);

        await cubit.startRecording('en');
        final path = recorder.recordedFilePath!;
        await cubit.finishRecording();
        await _settle();

        expect(recorder.cleanUpCalls, greaterThan(0));
        expect(File(path).existsSync(), isFalse);
      });

      test('never saves a task without explicit confirmation', () async {
        final cubit = build();

        await cubit.startRecording('en');
        await cubit.finishRecording();
        await _settle();

        expect(cubit.state.step, ComposerStep.review);
        expect(repository.createCalls, 0);
      });

      test('skipAiAndEditManually keeps the transcript for editing', () async {
        final transcription = FakeAudioTranscriptionRepository(
          result: 'water the plants tonight',
        );
        final ai = FakeAiTaskRepository();
        final cubit = build(transcription: transcription, ai: ai);

        await cubit.startRecording('en');
        await cubit.finishRecording();
        await _settle();

        cubit.skipAiAndEditManually();
        expect(cubit.state.step, ComposerStep.review);
        expect(cubit.state.draft!.sourceTranscript, 'water the plants tonight');
        expect(cubit.state.draft!.description, startsWith('- '));
      });
    });
  });
}
