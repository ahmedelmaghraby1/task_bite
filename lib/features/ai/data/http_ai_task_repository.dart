import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:taskbite/features/ai/data/ai_config.dart';
import 'package:taskbite/features/ai/data/ai_task_draft_parser.dart';
import 'package:taskbite/features/ai/domain/models/ai_task_request.dart';
import 'package:taskbite/features/ai/domain/models/task_draft.dart';
import 'package:taskbite/features/ai/domain/repositories/ai_task_repository.dart';

/// Stage B of the pipeline: sends a verified transcript to an
/// OpenAI-compatible chat-completions endpoint and parses a structured task
/// draft out of the response.
///
/// The endpoint is expected to speak the OpenAI chat-completions request shape,
/// so this works against Groq directly (development) or a server-side proxy
/// (production). Credentials are never hardcoded: [config] is injected, and the
/// app should point at a proxy so no key ships in the binary.
class HttpAiTaskRepository implements AiTaskRepository {
  HttpAiTaskRepository({
    required this.config,
    required this.parser,
    required http.Client client,
  }) : _client = client;

  final AiConfig config;
  final AiTaskDraftParser parser;
  final http.Client _client;

  @override
  bool get isConfigured => config.taskEndpoint.trim().isNotEmpty;

  static const String systemPrompt =
      'You convert a user\'s spoken task description into a concise, '
      'actionable task draft. Return ONLY a JSON object with this exact '
      'shape: {"title": string, "description": string, "dueDate": string or '
      'null}. Rules: '
      '1. The title must be a short, meaningful summary of the intent '
      '(5-10 words). '
      '2. The description MUST be a list of concrete actions taken from the '
      'user\'s words, one per line, each line starting with "- ". Never return '
      'a single paragraph. '
      '3. Never invent actions, deadlines, priorities or commitments that the '
      'user did not mention. '
      '4. Only set dueDate when the user explicitly mentions a date or '
      'deadline. Resolve relative expressions (for example "tomorrow", "next '
      'Thursday", "in two days") against the current local date supplied '
      'below, and use the ISO format YYYY-MM-DD. If the user gave no deadline, '
      'or the date cannot be resolved reliably, use null instead of guessing. '
      '5. Respond in the same language as the user\'s text.';

  /// The per-request temporal context appended to [systemPrompt].
  ///
  /// Without the current local date a model cannot resolve "next Thursday"
  /// reliably; the offset is included so date math happens in the user's
  /// local calendar. [now] is injectable for tests.
  static String dateContext(DateTime now) {
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final date =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final time =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    return 'Current local date: $date. Current local time: $time '
        '(UTC$sign$hours:$minutes). Resolve all relative deadlines against '
        'this local date.';
  }

  @override
  Future<TaskDraft> generateTaskDraft(AiTaskRequest request) async {
    if (!isConfigured) {
      throw const AiTaskException(
        AiTaskErrorKind.notConfigured,
        'AI task endpoint is not configured (missing TASK_AI_TASK_ENDPOINT).',
      );
    }
    if (request.isEmpty) {
      throw const AiTaskException(
        AiTaskErrorKind.invalidResponse,
        'Empty transcript cannot be processed.',
      );
    }

    final payload = jsonEncode({
      'model': config.resolvedTaskModel,
      'temperature': 0.3,
      'messages': [
        {
          'role': 'system',
          'content': '$systemPrompt\n\n${dateContext(DateTime.now())}',
        },
        {'role': 'user', 'content': request.transcript},
      ],
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(config.taskEndpoint),
            headers: {
              'Content-Type': 'application/json',
              if (config.hasInlineCredentials)
                'Authorization': 'Bearer ${config.apiKey}',
            },
            body: payload,
          )
          .timeout(config.timeout);
    } on TimeoutException {
      throw const AiTaskException(
        AiTaskErrorKind.timeout,
        'The AI provider did not respond in time.',
      );
    } on http.ClientException catch (e) {
      throw AiTaskException(AiTaskErrorKind.network, e.message);
    } catch (_) {
      throw const AiTaskException(
        AiTaskErrorKind.network,
        'Could not reach the AI provider.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AiTaskException(
        AiTaskErrorKind.unauthorized,
        'The AI provider rejected the configured credentials.',
      );
    }
    if (response.statusCode == 429) {
      throw const AiTaskException(
        AiTaskErrorKind.rateLimited,
        'The AI provider is rate limiting requests.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiTaskException(
        AiTaskErrorKind.serverError,
        'The AI provider returned HTTP ${response.statusCode}.',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const AiTaskException(
          AiTaskErrorKind.invalidResponse,
          'AI response root is not an object.',
        );
      }
      return parser.parseChatCompletion(decoded);
    } on AiTaskException {
      rethrow;
    } catch (e) {
      throw AiTaskException(
        AiTaskErrorKind.invalidResponse,
        'Could not parse the AI response: $e',
      );
    }
  }

  void dispose() => _client.close();
}
