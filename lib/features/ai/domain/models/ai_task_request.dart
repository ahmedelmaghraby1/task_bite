/// Request payload for Stage B of the AI pipeline: turning a verified
/// transcript into a structured task draft.
///
/// Audio never reaches this request — transcription happens in Stage A and
/// produces the [transcript] consumed here.
class AiTaskRequest {
  const AiTaskRequest({required this.transcript, this.languageHint});

  /// The user's spoken words, already validated as non-empty by the caller.
  final String transcript;

  /// Preferred output language (e.g. `en` or `ar`), used to instruct the model
  /// to answer in the same language as the user.
  final String? languageHint;

  bool get isEmpty => transcript.trim().isEmpty;
}
