import 'dart:convert';

import 'package:taskbite/features/ai/domain/models/task_draft.dart';
import 'package:taskbite/features/ai/domain/repositories/ai_task_repository.dart';
import 'package:taskbite/features/ai/domain/text/bullet_text.dart';

/// Parses and validates the structured JSON returned by the AI provider.
///
/// Expected schema (all fields optional except `title`, which must be a
/// non-empty string):
///
/// ```json
/// {
///   "title": "Prepare and Release the Application Update",
///   "description": "- Review and fix authentication errors.\n- Test the login flow.",
///   "dueDate": "2026-10-15"
/// }
/// ```
///
/// The parser is deliberately strict about the fields that matter for saving
/// a task and tolerant about everything else. `dueDate` is only accepted when
/// it resolves to a real calendar date (ISO 8601 or a date-only string).
class AiTaskDraftParser {
  const AiTaskDraftParser();

  TaskDraft parseJsonObject(Map<String, dynamic> json) {
    final rawTitle = json['title'];
    if (rawTitle is! String || rawTitle.trim().isEmpty) {
      throw const AiTaskException(
        AiTaskErrorKind.invalidResponse,
        'Missing or empty "title" in AI response.',
      );
    }

    final rawDescription = json['description'];
    // The product requires bullet-point descriptions. Providers mostly comply,
    // but a model that returns a paragraph is normalized instead of rejected.
    final description =
        rawDescription is String ? normalizeToBulletPoints(rawDescription) : '';

    final dueDate = _parseDueDate(json['dueDate']);
    final rawTranscript = json['transcript'];

    return TaskDraft(
      title: rawTitle.trim(),
      description: description,
      dueDate: dueDate,
      sourceTranscript: rawTranscript is String ? rawTranscript.trim() : null,
    );
  }

  /// Extracts the chat-completion content and parses it, tolerating common
  /// wrapper shapes such as Markdown code fences or a JSON string payload.
  TaskDraft parseChatCompletion(Map<String, dynamic> body) {
    final candidate = _extractContentText(body);
    if (candidate == null) {
      throw const AiTaskException(
        AiTaskErrorKind.invalidResponse,
        'No message content found in AI response.',
      );
    }
    return _parseText(candidate);
  }

  TaskDraft parseText(String raw) => _parseText(raw);

  TaskDraft _parseText(String raw) {
    String candidate = raw;
    final extracted = _extractJsonObject(raw);
    if (extracted != null) candidate = extracted;
    Object? decoded;
    try {
      decoded = jsonDecode(candidate);
    } on FormatException {
      throw const AiTaskException(
        AiTaskErrorKind.invalidResponse,
        'AI response is not valid JSON.',
      );
    }
    if (decoded is String) {
      // Some providers wrap the object in a JSON string.
      try {
        decoded = jsonDecode(decoded);
      } on FormatException {
        throw const AiTaskException(
          AiTaskErrorKind.invalidResponse,
          'AI response is not valid JSON.',
        );
      }
    }
    if (decoded is! Map<String, dynamic>) {
      throw const AiTaskException(
        AiTaskErrorKind.invalidResponse,
        'AI response JSON root is not an object.',
      );
    }
    return parseJsonObject(decoded);
  }

  /// Locates the first top-level `{ ... }` group in the text. Works for raw
  /// JSON as well as JSON inside markdown fences or prose. Braces inside
  /// quoted strings (including a JSON object wrapped in a JSON string) are
  /// ignored, so `"{\"title\":...}"` is left for the whole-text decode below
  /// instead of being misread as a nested object.
  static String? _extractJsonObject(String text) {
    int depth = 0;
    bool inString = false;
    bool escaped = false;
    int? start;
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (c == r'\') {
          escaped = true;
        } else if (c == '"') {
          inString = false;
        }
        continue;
      }
      if (c == '"') {
        inString = true;
      } else if (c == '{') {
        start ??= i;
        depth++;
      } else if (c == '}') {
        if (start == null) continue;
        depth--;
        if (depth == 0) {
          return text.substring(start, i + 1);
        }
      }
    }
    return null;
  }

  static String? _extractContentText(Map<String, dynamic> body) {
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map<String, dynamic>) return null;
    final message = first['message'];
    if (message is Map<String, dynamic>) {
      final content = message['content'];
      if (content is String && content.trim().isNotEmpty) return content;
      return null;
    }
    // Some providers return the text directly in the choice.
    final text = first['text'];
    if (text is String && text.trim().isNotEmpty) return text;
    return null;
  }

  static DateTime? _parseDueDate(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return null;
    // A valid date component is required; reject partial timestamps.
    if (parsed.year <= 0 || parsed.month < 1 || parsed.day < 1) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
