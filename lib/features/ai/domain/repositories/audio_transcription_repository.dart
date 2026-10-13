import 'dart:io';

/// Stage A contract: converts a recorded audio file into text.
///
/// Implementations talk to a speech-to-text provider (Groq Whisper by default)
/// either directly (development) or through a server-side proxy that keeps the
/// provider key off the device (production). Failure is reported with
/// [AiTaskException] from the shared AI error taxonomy.
abstract interface class AudioTranscriptionRepository {
  /// Whether a transcription endpoint is configured. When `false` callers
  /// surface a clear setup error instead of uploading.
  bool get isConfigured;

  /// Transcribes [audioFile]. [languageHint] is an ISO-639-1 code (`en`, `ar`)
  /// or `null` to let the model auto-detect the language.
  ///
  /// Throws [AiTaskException] on configuration, network, provider or response
  /// errors.
  Future<String> transcribe({required File audioFile, String? languageHint});
}
