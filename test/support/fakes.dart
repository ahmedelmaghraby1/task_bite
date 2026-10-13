import 'dart:async';
import 'dart:io';

import 'package:taskbite/features/ai/domain/models/ai_task_request.dart';
import 'package:taskbite/features/ai/domain/models/task_draft.dart';
import 'package:taskbite/features/ai/domain/repositories/ai_task_repository.dart';
import 'package:taskbite/features/ai/domain/repositories/audio_transcription_repository.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/domain/models/stored_task.dart';
import 'package:taskbite/features/tasks/domain/repositories/task_repository.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository([List<StoredTask>? initial])
    : _items = <StoredTask>[...?initial];

  final List<StoredTask> _items;
  final StreamController<List<StoredTask>> _controller =
      StreamController<List<StoredTask>>.broadcast(sync: true);
  int _nextKey = 1000;

  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  Object? loadError;
  bool throwOnCreate = false;

  List<StoredTask> get items => List<StoredTask>.unmodifiable(_items);

  List<StoredTask> _snapshot() => List<StoredTask>.of(_items);

  void _emit() {
    if (!_controller.isClosed) _controller.add(_snapshot());
  }

  @override
  Stream<List<StoredTask>> watchTasks() => _controller.stream;

  @override
  Future<List<StoredTask>> loadTasks() async {
    if (loadError != null) throw loadError!;
    return _snapshot();
  }

  @override
  Future<int> evaluateOverdue() async {
    if (loadError != null) throw loadError!;
    final now = DateTime.now();
    var changed = 0;
    for (var i = 0; i < _items.length; i++) {
      final entry = _items[i];
      if (!entry.task.shouldBecomeFailed(now: now)) continue;
      final updated = entry.task.copyWith(status: TaskStatus.failed);
      updated.markUpdated(at: now);
      _items[i] = StoredTask(key: entry.key, task: updated);
      changed++;
    }
    _emit();
    return changed;
  }

  @override
  Future<StoredTask> createTask({
    required String title,
    required String content,
    DateTime? dueDate,
  }) async {
    createCalls++;
    if (throwOnCreate) throw Exception('create failed');
    final id = _nextKey++;
    final task = TaskModel(
      title: title,
      content: content,
      dueDate: dueDate,
      status: TaskStatus.newTask,
      createdAt: DateTime.now(),
    );
    final stored = StoredTask(key: id, task: task);
    _items.add(stored);
    _emit();
    return stored;
  }

  @override
  Future<void> updateStatus({
    required dynamic key,
    required TaskStatus status,
  }) async {
    updateCalls++;
    final idx = _items.indexWhere((e) => e.key == key);
    if (idx < 0) throw Exception('Not found');
    final current = _items[idx];
    final updated = current.task.copyWith(status: status);
    updated.markUpdated();
    _items[idx] = StoredTask(key: current.key, task: updated);
    _emit();
  }

  @override
  Future<void> updateTask({
    required dynamic key,
    required String title,
    required String content,
    DateTime? dueDate,
  }) async {
    updateCalls++;
    final idx = _items.indexWhere((e) => e.key == key);
    if (idx < 0) throw Exception('Not found');
    final current = _items[idx];
    final updated = current.task.copyWith(
      title: title,
      content: content,
      dueDate: dueDate,
      clearDueDate: dueDate == null,
    );
    updated.markUpdated();
    _items[idx] = StoredTask(key: current.key, task: updated);
    _emit();
  }

  @override
  Future<void> deleteTask({required dynamic key}) async {
    deleteCalls++;
    _items.removeWhere((e) => e.key == key);
    _emit();
  }

  Future<void> dispose() => _controller.close();
}

/// Stage B fake. [requestedTranscripts] records every transcript it was asked
/// to turn into a draft so tests can assert the audio → transcript hand-off.
class FakeAiTaskRepository implements AiTaskRepository {
  FakeAiTaskRepository({this.result, this.isConfigured = true, this.error});

  TaskDraft? result;
  Object? error;
  int calls = 0;
  final List<String> requestedTranscripts = [];

  @override
  bool isConfigured;

  @override
  Future<TaskDraft> generateTaskDraft(AiTaskRequest request) async {
    calls++;
    requestedTranscripts.add(request.transcript);
    if (error != null) throw error!;
    if (result != null) return result!;
    return TaskDraft(
      title: 'Draft title',
      description: request.transcript,
      sourceTranscript: request.transcript,
    );
  }
}

/// Stage A fake. Returns [result] (or throws [error]) and records what it was
/// handed.
class FakeAudioTranscriptionRepository implements AudioTranscriptionRepository {
  FakeAudioTranscriptionRepository({
    this.result = 'buy milk tomorrow',
    this.isConfigured = true,
  });

  String result;
  Object? error;
  int calls = 0;
  File? lastFile;
  String? lastLanguageHint;

  @override
  bool isConfigured;

  @override
  Future<String> transcribe({
    required File audioFile,
    String? languageHint,
  }) async {
    calls++;
    lastFile = audioFile;
    lastLanguageHint = languageHint;
    if (error != null) throw error!;
    return result;
  }
}
