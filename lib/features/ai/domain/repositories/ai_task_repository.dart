import 'package:taskbite/features/ai/domain/models/ai_task_request.dart';
import 'package:taskbite/features/ai/domain/models/task_draft.dart';

/// The failure categories shared by both AI stages (transcription and task
/// generation). Presentation maps each category to localized copy; the
/// exception [message] stays technical for debugging.
enum AiTaskErrorKind {
  /// No provider configured (missing endpoint or credentials).
  notConfigured,

  /// Could not reach the configured endpoint (offline, DNS, connection).
  network,

  /// The request took longer than the configured timeout.
  timeout,

  /// The provider rejected the credentials (401/403).
  unauthorized,

  /// The provider is rate limiting (429) or otherwise busy.
  rateLimited,

  /// The provider returned an HTTP error we could not categorize.
  serverError,

  /// The response body was not valid JSON or did not match the schema.
  invalidResponse,
}

class AiTaskException implements Exception {
  const AiTaskException(this.kind, this.message);

  final AiTaskErrorKind kind;
  final String message;

  @override
  String toString() => 'AiTaskException(${kind.name}): $message';
}

/// Stage B contract: turns a verified transcript into a structured task draft
/// (concise title + bullet-point description + optional due date).
abstract interface class AiTaskRepository {
  /// Whether enough configuration exists to call the provider. When `false`
  /// callers should surface a clear setup error instead of attempting a call.
  bool get isConfigured;

  Future<TaskDraft> generateTaskDraft(AiTaskRequest request);
}
