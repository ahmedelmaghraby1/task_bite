import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taskbite/features/ai/data/ai_config.dart';
import 'package:taskbite/features/ai/data/ai_task_draft_parser.dart';
import 'package:taskbite/features/ai/data/http_ai_task_repository.dart';
import 'package:taskbite/features/ai/domain/models/ai_task_request.dart';
import 'package:taskbite/features/ai/domain/repositories/ai_task_repository.dart';

const _request = AiTaskRequest(transcript: 'buy milk tomorrow');

HttpAiTaskRepository _repo(
  MockClient client, {
  bool configured = true,
  Duration timeout = const Duration(milliseconds: 200),
}) {
  return HttpAiTaskRepository(
    config: AiConfig(
      transcriptionEndpoint: '',
      taskEndpoint:
          configured ? 'https://example.test/v1/chat/completions' : '',
      apiKey: 'test-key',
      taskModel: 'test-model',
      timeout: timeout,
    ),
    parser: const AiTaskDraftParser(),
    client: client,
  );
}

void main() {
  group('HttpAiTaskRepository', () {
    test(
      'parses a successful chat completion and sends expected headers',
      () async {
        final client = MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer test-key');
          expect(request.headers['Content-Type'], 'application/json');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['model'], 'test-model');
          expect(body['messages'], hasLength(2));
          expect((body['messages'] as List)[1]['content'], _request.transcript);
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': '{"title":"Buy milk","description":"- milk"}',
                  },
                },
              ],
            }),
            200,
          );
        });

        final draft = await _repo(client).generateTaskDraft(_request);
        expect(draft.title, 'Buy milk');
        expect(draft.description, '- milk');
      },
    );

    test('short-circuits when the provider is not configured', () async {
      var networkCalled = false;
      final client = MockClient((_) async {
        networkCalled = true;
        return http.Response('{}', 200);
      });

      await expectLater(
        _repo(client, configured: false).generateTaskDraft(_request),
        throwsA(
          isA<AiTaskException>().having(
            (e) => e.kind,
            'kind',
            AiTaskErrorKind.notConfigured,
          ),
        ),
      );
      expect(networkCalled, isFalse);
    });

    test('rejects an empty transcript before calling the network', () async {
      var networkCalled = false;
      final client = MockClient((_) async {
        networkCalled = true;
        return http.Response('{}', 200);
      });

      await expectLater(
        _repo(client).generateTaskDraft(const AiTaskRequest(transcript: '   ')),
        throwsA(isA<AiTaskException>()),
      );
      expect(networkCalled, isFalse);
    });

    test('maps 401 to unauthorized', () async {
      final client = MockClient((_) async => http.Response('nope', 401));
      await expectLater(
        _repo(client).generateTaskDraft(_request),
        throwsA(
          isA<AiTaskException>().having(
            (e) => e.kind,
            'kind',
            AiTaskErrorKind.unauthorized,
          ),
        ),
      );
    });

    test('maps 403 to unauthorized', () async {
      final client = MockClient((_) async => http.Response('forbidden', 403));
      await expectLater(
        _repo(client).generateTaskDraft(_request),
        throwsA(
          isA<AiTaskException>().having(
            (e) => e.kind,
            'kind',
            AiTaskErrorKind.unauthorized,
          ),
        ),
      );
    });

    test('maps 429 to rate limited', () async {
      final client = MockClient((_) async => http.Response('slow down', 429));
      await expectLater(
        _repo(client).generateTaskDraft(_request),
        throwsA(
          isA<AiTaskException>().having(
            (e) => e.kind,
            'kind',
            AiTaskErrorKind.rateLimited,
          ),
        ),
      );
    });

    test('maps other HTTP errors to server error', () async {
      final client = MockClient((_) async => http.Response('boom', 500));
      await expectLater(
        _repo(client).generateTaskDraft(_request),
        throwsA(
          isA<AiTaskException>().having(
            (e) => e.kind,
            'kind',
            AiTaskErrorKind.serverError,
          ),
        ),
      );
    });

    test('maps a non-JSON success body to invalid response', () async {
      final client = MockClient(
        (_) async => http.Response('this is not json', 200),
      );
      await expectLater(
        _repo(client).generateTaskDraft(_request),
        throwsA(
          isA<AiTaskException>().having(
            (e) => e.kind,
            'kind',
            AiTaskErrorKind.invalidResponse,
          ),
        ),
      );
    });

    test('maps a JSON array root to invalid response', () async {
      final client = MockClient((_) async => http.Response('[]', 200));
      await expectLater(
        _repo(client).generateTaskDraft(_request),
        throwsA(
          isA<AiTaskException>().having(
            (e) => e.kind,
            'kind',
            AiTaskErrorKind.invalidResponse,
          ),
        ),
      );
    });

    test('maps a timeout to the timeout kind', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return http.Response('{}', 200);
      });

      await expectLater(
        _repo(
          client,
          timeout: const Duration(milliseconds: 100),
        ).generateTaskDraft(_request),
        throwsA(
          isA<AiTaskException>().having(
            (e) => e.kind,
            'kind',
            AiTaskErrorKind.timeout,
          ),
        ),
      );
    });

    test('maps a connection failure to network', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('no route to host'),
      );
      await expectLater(
        _repo(client).generateTaskDraft(_request),
        throwsA(
          isA<AiTaskException>().having(
            (e) => e.kind,
            'kind',
            AiTaskErrorKind.network,
          ),
        ),
      );
    });

    test('falls back to the default model when none is configured', () async {
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], AiConfig.defaultTaskModelName);
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': '{"title":"T","description":""}'},
              },
            ],
          }),
          200,
        );
      });

      final repository = HttpAiTaskRepository(
        config: const AiConfig(
          transcriptionEndpoint: '',
          taskEndpoint: 'https://example.test/v1/chat/completions',
          apiKey: '',
          taskModel: '',
        ),
        parser: const AiTaskDraftParser(),
        client: client,
      );
      final draft = await repository.generateTaskDraft(_request);
      expect(draft.title, 'T');
    });

    test(
      'sends the current local date so relative deadlines resolve',
      () async {
        final client = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final messages = body['messages'] as List;
          final system = messages.first as Map<String, dynamic>;
          expect(
            system['content'],
            contains(HttpAiTaskRepository.systemPrompt),
          );
          expect(system['content'], contains('Current local date:'));
          // The transcript stays the only user message.
          expect(messages.last['role'], 'user');
          expect(messages.last['content'], _request.transcript);
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content':
                        '{"title":"Release notes","description":"- upload",'
                        '"dueDate":"2026-10-16"}',
                  },
                },
              ],
            }),
            200,
          );
        });

        final draft = await _repo(client).generateTaskDraft(_request);
        expect(draft.title, 'Release notes');
        expect(draft.dueDate, DateTime(2026, 10, 16));
      },
    );

    test('dateContext formats the local date, time and UTC offset', () {
      final context = HttpAiTaskRepository.dateContext(
        DateTime(2026, 10, 13, 9, 5),
      );
      expect(context, contains('2026-10-13'));
      expect(context, contains('09:05'));
      expect(context, contains('UTC'));
    });
  });
}
