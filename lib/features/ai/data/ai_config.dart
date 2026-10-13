import 'package:flutter/foundation.dart';

/// Runtime configuration for the two-stage AI pipeline.
///
/// **No secret is ever required in the app.** The recommended production setup
/// points both endpoints at a server-side proxy that holds the provider key
/// (see `backend/` and `AI_SETUP.md`). For local development against a provider
/// directly, an optional [apiKey] can be supplied at build time.
///
/// Configuration comes from `--dart-define` (or `--dart-define-from-file`):
///
/// ```sh
/// # Production / proxy (no key in the app):
/// flutter run \
///   --dart-define=TASK_AI_TRANSCRIBE_ENDPOINT=https://your-proxy.example/transcribe \
///   --dart-define=TASK_AI_TASK_ENDPOINT=https://your-proxy.example/task
///
/// # Local development against Groq directly (key stays on your machine):
/// flutter run \
///   --dart-define=TASK_AI_TRANSCRIBE_ENDPOINT=https://api.groq.com/openai/v1/audio/transcriptions \
///   --dart-define=TASK_AI_TASK_ENDPOINT=https://api.groq.com/openai/v1/chat/completions \
///   --dart-define=TASK_AI_API_KEY=gsk_...
/// ```
///
/// When an endpoint is blank the app reports a configuration error instead of
/// pretending the service is connected.
@immutable
class AiConfig {
  const AiConfig({
    required this.transcriptionEndpoint,
    required this.taskEndpoint,
    this.apiKey = '',
    this.transcriptionModel = '',
    this.taskModel = '',
    this.timeout = const Duration(seconds: 60),
  });

  static const String defaultTranscriptionEndpoint = String.fromEnvironment(
    'TASK_AI_TRANSCRIBE_ENDPOINT',
    defaultValue: '',
  );
  static const String defaultTaskEndpoint = String.fromEnvironment(
    'TASK_AI_TASK_ENDPOINT',
    defaultValue: '',
  );
  static const String defaultApiKey = String.fromEnvironment(
    'TASK_AI_API_KEY',
    defaultValue: '',
  );
  static const String defaultTranscriptionModel = String.fromEnvironment(
    'TASK_AI_TRANSCRIBE_MODEL',
    defaultValue: '',
  );
  static const String defaultTaskModel = String.fromEnvironment(
    'TASK_AI_MODEL',
    defaultValue: '',
  );
  static const int defaultTimeoutMillis = int.fromEnvironment(
    'TASK_AI_TIMEOUT_MS',
    defaultValue: 60000,
  );

  /// Builds a config from the compile-time environment.
  factory AiConfig.fromEnvironment() => AiConfig(
    transcriptionEndpoint: defaultTranscriptionEndpoint,
    taskEndpoint: defaultTaskEndpoint,
    apiKey: defaultApiKey,
    transcriptionModel: defaultTranscriptionModel,
    taskModel: defaultTaskModel,
    timeout: const Duration(milliseconds: defaultTimeoutMillis),
  );

  /// Convenience for a single proxy base URL that exposes `/transcribe` and
  /// `/task`.
  factory AiConfig.forProxy(
    String baseUrl, {
    String? apiKey,
    Duration? timeout,
  }) {
    final trimmed = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    return AiConfig(
      transcriptionEndpoint: '$trimmed/transcribe',
      taskEndpoint: '$trimmed/task',
      apiKey: apiKey ?? '',
      timeout: timeout ?? const Duration(seconds: 60),
    );
  }

  /// Stage A endpoint (speech-to-text). Blank disables voice input.
  final String transcriptionEndpoint;

  /// Stage B endpoint (chat completions). Blank disables task generation.
  final String taskEndpoint;

  /// Optional provider key. Only ever set for local development; production
  /// builds must leave this empty and let the proxy hold the secret.
  final String apiKey;

  final String transcriptionModel;
  final String taskModel;
  final Duration timeout;

  /// Both stages must be configured for the voice flow to work end to end.
  bool get isConfigured =>
      transcriptionEndpoint.trim().isNotEmpty && taskEndpoint.trim().isNotEmpty;

  /// Whether an inline provider key was supplied (development only).
  bool get hasInlineCredentials => apiKey.trim().isNotEmpty;

  /// The Whisper model to request, falling back to a current default.
  String get resolvedTranscriptionModel {
    final value = transcriptionModel.trim();
    return value.isEmpty ? defaultTranscriptionModelName : value;
  }

  /// The chat model to request, falling back to a current default.
  String get resolvedTaskModel {
    final value = taskModel.trim();
    return value.isEmpty ? defaultTaskModelName : value;
  }

  /// Fast multilingual Whisper model (Groq STT).
  static const String defaultTranscriptionModelName = 'whisper-large-v3-turbo';

  /// Current Groq chat model suited to structured extraction. Swap to
  /// `llama-3.1-8b-instant` for a larger free-tier daily quota.
  static const String defaultTaskModelName = 'llama-3.3-70b-versatile';

  @override
  String toString() =>
      'AiConfig(transcribe=$transcriptionEndpoint, task=$taskEndpoint, '
      'hasKey=$hasInlineCredentials)';
}
