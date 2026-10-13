import 'package:flutter_test/flutter_test.dart';
import 'package:taskbite/features/ai/data/ai_task_draft_parser.dart';
import 'package:taskbite/features/ai/domain/repositories/ai_task_repository.dart';

const parser = AiTaskDraftParser();

void main() {
  group('AiTaskDraftParser.parseJsonObject', () {
    test('parses title, description and due date', () {
      final draft = parser.parseJsonObject({
        'title': 'Prepare release',
        'description': '- Write notes\n- Tag build',
        'dueDate': '2026-10-15',
      });

      expect(draft.title, 'Prepare release');
      expect(draft.description, '- Write notes\n- Tag build');
      expect(draft.dueDate, DateTime(2026, 10, 15));
    });

    test('tolerates a missing description', () {
      final draft = parser.parseJsonObject({'title': 'Only a title'});
      expect(draft.title, 'Only a title');
      expect(draft.description, '');
      expect(draft.dueDate, isNull);
    });

    test('throws when the title is missing or blank', () {
      expect(
        () => parser.parseJsonObject({'description': 'no title'}),
        throwsA(
          isA<AiTaskException>().having(
            (e) => e.kind,
            'kind',
            AiTaskErrorKind.invalidResponse,
          ),
        ),
      );
      expect(
        () => parser.parseJsonObject({'title': '   '}),
        throwsA(isA<AiTaskException>()),
      );
    });

    test('ignores an unparseable due date', () {
      final draft = parser.parseJsonObject({
        'title': 'No date',
        'dueDate': 'sometime next week',
      });
      expect(draft.dueDate, isNull);
    });
  });

  group('AiTaskDraftParser.parseChatCompletion', () {
    test('reads content from the OpenAI message shape', () {
      final draft = parser.parseChatCompletion({
        'choices': [
          {
            'message': {
              'content':
                  '{"title":"Buy groceries","description":"- Milk\\n- Eggs"}',
            },
          },
        ],
      });
      expect(draft.title, 'Buy groceries');
      expect(draft.description, '- Milk\n- Eggs');
    });

    test('reads content wrapped in a markdown code fence', () {
      final draft = parser.parseChatCompletion({
        'choices': [
          {
            'message': {
              'content': 'Here you go:\n```json\n{"title":"Fenced"}\n```',
            },
          },
        ],
      });
      expect(draft.title, 'Fenced');
    });

    test('reads a bare text choice', () {
      final draft = parser.parseChatCompletion({
        'choices': [
          {'text': '{"title":"From text"}'},
        ],
      });
      expect(draft.title, 'From text');
    });

    test('throws when there is no content', () {
      expect(
        () => parser.parseChatCompletion({'choices': <dynamic>[]}),
        throwsA(
          isA<AiTaskException>().having(
            (e) => e.kind,
            'kind',
            AiTaskErrorKind.invalidResponse,
          ),
        ),
      );
    });

    test('supports JSON wrapped in a JSON string', () {
      final draft = parser.parseText('"{\\"title\\":\\"Double encoded\\"}"');
      expect(draft.title, 'Double encoded');
    });

    test('throws for non-JSON text', () {
      expect(
        () => parser.parseText('not json at all'),
        throwsA(isA<AiTaskException>()),
      );
    });
  });
}
