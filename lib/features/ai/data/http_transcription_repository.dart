import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:taskbite/features/ai/data/ai_config.dart';
import 'package:taskbite/features/ai/domain/repositories/ai_task_repository.dart';
import 'package:taskbite/features/ai/domain/repositories/audio_transcription_repository.dart';

/// Stage A of the pipeline: uploads recorded audio as multipart form data and
/// returns the transcript.
///
/// Speaks the OpenAI/Groq transcription shape (`POST` multipart with a `file`
/// field and a `model` field, responding with `{"text": "..."}`). Point it at
/// Groq directly for development, or at a server-side proxy in production so
/// the provider key never ships in the app.
class HttpTranscriptionRepository implements AudioTranscriptionRepository {
  HttpTranscriptionRepository({
    required this.config,
    required http.Client client,
  }) : _client = client;

  final AiConfig config;
  final http.Client _client;

  static const String _fileField = 'file';

  @override
  bool get isConfigured => config.transcriptionEndpoint.trim().isNotEmpty;

  @override
  Future<String> transcribe({
    required File audioFile,
    String? languageHint,
  }) async {
    if (!isConfigured) {
      throw const AiTaskException(
        AiTaskErrorKind.notConfigured,
        'Transcription endpoint is not configured '
        '(missing TASK_AI_TRANSCRIBE_ENDPOINT).',
      );
    }

    if (!await audioFile.exists() || await audioFile.length() == 0) {
      throw const AiTaskException(
        AiTaskErrorKind.invalidResponse,
        'The recording contains no audio data.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(config.transcriptionEndpoint),
    );
    request.headers['Accept'] = 'application/json';
    if (config.hasInlineCredentials) {
      request.headers['Authorization'] = 'Bearer ${config.apiKey}';
    }
    request.fields['model'] = config.resolvedTranscriptionModel;
    final language = languageHint?.trim();
    if (language != null && language.isNotEmpty) {
      request.fields['language'] = language;
    }
    request.files.add(
      await http.MultipartFile.fromPath(
        _fileField,
        audioFile.path,
        filename: _fileName(audioFile.path),
        contentType: _contentTypeFor(audioFile.path),
      ),
    );

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(config.timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const AiTaskException(
        AiTaskErrorKind.timeout,
        'The transcription service did not respond in time.',
      );
    } on http.ClientException catch (e) {
      throw AiTaskException(AiTaskErrorKind.network, e.message);
    } catch (_) {
      throw const AiTaskException(
        AiTaskErrorKind.network,
        'Could not reach the transcription service.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AiTaskException(
        AiTaskErrorKind.unauthorized,
        'The transcription service rejected the configured credentials.',
      );
    }
    if (response.statusCode == 413) {
      throw const AiTaskException(
        AiTaskErrorKind.invalidResponse,
        'The recording is too large for the transcription service.',
      );
    }
    if (response.statusCode == 429) {
      throw const AiTaskException(
        AiTaskErrorKind.rateLimited,
        'The transcription service is rate limiting requests.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiTaskException(
        AiTaskErrorKind.serverError,
        'The transcription service returned HTTP ${response.statusCode}.',
      );
    }

    return _parseTranscript(response.body);
  }

  static String _parseTranscript(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw const AiTaskException(
        AiTaskErrorKind.invalidResponse,
        'The transcription response was empty.',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException {
      // Some proxies respond with the raw text body.
      return trimmed;
    }

    if (decoded is Map<String, dynamic>) {
      final text = decoded['text'];
      if (text is String) return text.trim();
    }
    throw const AiTaskException(
      AiTaskErrorKind.invalidResponse,
      'The transcription response did not contain a "text" field.',
    );
  }

  static String _fileName(String path) => path.split(RegExp(r'[\\/]')).last;

  static MediaType _contentTypeFor(String path) {
    final name = _fileName(path).toLowerCase();
    final dot = name.lastIndexOf('.');
    final extension = dot < 0 ? '' : name.substring(dot);
    switch (extension) {
      case '.m4a':
      case '.mp4':
      case '.aac':
        return MediaType('audio', 'mp4');
      case '.mp3':
      case '.mpeg':
      case '.mpga':
        return MediaType('audio', 'mpeg');
      case '.wav':
        return MediaType('audio', 'wav');
      case '.ogg':
      case '.oga':
        return MediaType('audio', 'ogg');
      case '.webm':
        return MediaType('audio', 'webm');
      case '.flac':
        return MediaType('audio', 'flac');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  void dispose() => _client.close();
}
