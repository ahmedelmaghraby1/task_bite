/// Diagnostics for a finished recording before it is uploaded.
///
/// The recorder can finish "successfully" but still produce nothing usable
/// (permission revoked mid-session, an encoder that silently wrote zero bytes,
/// an unexpected format). This classifier keeps that decision pure and
/// testable instead of hiding it inside the service.
enum RecordingProblem {
  /// The recorder never produced a path, or the file disappeared.
  missing,

  /// The file exists but is empty (no audio data was captured).
  empty,

  /// The container/codec is not accepted by the transcription endpoint.
  unsupportedFormat,

  /// The file exceeds the upload ceiling (Groq's free tier caps at 25 MB).
  tooLarge,
}

/// Container extensions accepted by the Groq transcription endpoint
/// (FLAC, MP3, M4A, MPEG, MPGA, OGG, WAV, WEBM) plus a couple of common
/// aliases produced by mobile encoders.
const Set<String> kSupportedAudioExtensions = <String>{
  '.m4a',
  '.mp4',
  '.aac',
  '.mp3',
  '.wav',
  '.ogg',
  '.oga',
  '.webm',
  '.flac',
  '.mpeg',
  '.mpga',
};

/// Conservative upload ceiling. The Groq free tier rejects audio over 25 MB.
const int kMaxAudioBytes = 25 * 1024 * 1024;

/// Returns the problem with a recording, or `null` when it is usable.
///
/// [path] is only inspected for its extension; callers pass real filesystem
/// facts for existence and length so this stays free of I/O.
RecordingProblem? classifyRecording({
  required bool exists,
  required int lengthInBytes,
  required String path,
  int maxBytes = kMaxAudioBytes,
}) {
  if (!exists) return RecordingProblem.missing;
  if (lengthInBytes <= 0) return RecordingProblem.empty;
  final extension = audioExtensionOf(path);
  if (!kSupportedAudioExtensions.contains(extension)) {
    return RecordingProblem.unsupportedFormat;
  }
  if (lengthInBytes > maxBytes) return RecordingProblem.tooLarge;
  return null;
}

/// Lower-cased extension (including the dot) of [path], or `''`.
String audioExtensionOf(String path) {
  final name = path.split(RegExp(r'[\\/]')).last;
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return '';
  return name.substring(dot).toLowerCase();
}
