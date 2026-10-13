import 'package:flutter_test/flutter_test.dart';
import 'package:taskbite/features/ai/domain/text/bullet_text.dart';

void main() {
  group('bullet text', () {
    test('toBulletPoints splits on commas and sentence terminators', () {
      const text = 'buy milk, eggs, and bread. also call the dentist.';
      final result = toBulletPoints(text);
      expect(result, contains('- buy milk'));
      expect(result, contains('- eggs'));
      expect(result, contains('- bread'));
      expect(result, contains('- call the dentist'));
    });

    test(
      'normalizeToBulletPoints keeps existing bullets and canonicalizes markers',
      () {
        const text = '- Write notes\n• Test login';
        final result = normalizeToBulletPoints(text);
        expect(
          result,
          'Write notes'.contains('- Write notes')
              ? result
              : '- Write notes\n- Test login',
        );
        expect(result, contains('- Test login'));
        expect(result, contains('- Write notes'));
      },
    );

    test('normalizeToBulletPoints converts prose into bullets', () {
      const text =
          'I need to update the app and publish a release by Thursday.';
      final result = normalizeToBulletPoints(text);
      expect(result.startsWith('- '), isTrue);
      final bullets = result.split('\n');
      expect(bullets.length, greaterThanOrEqualTo(1));
    });

    test('handles empty input', () {
      expect(toBulletPoints(''), '');
      expect(normalizeToBulletPoints(''), '');
      expect(toBulletPoints('   '), '');
    });

    test('strips leading conjunctions', () {
      expect(toBulletPoints('and verify backups'), '- verify backups');
    });
  });
}
