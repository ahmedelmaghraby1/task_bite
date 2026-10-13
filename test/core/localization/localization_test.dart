import 'package:flutter_test/flutter_test.dart';
import 'package:taskbite/core/localization/lang/ar_eg.dart';
import 'package:taskbite/core/localization/lang/en_us.dart';

void main() {
  group('localization maps', () {
    test('English and Arabic expose the exact same keys', () {
      final en = enUs.keys.toSet();
      final ar = arEg.keys.toSet();

      expect(
        en.difference(ar),
        isEmpty,
        reason: 'Keys present in English but missing in Arabic',
      );
      expect(
        ar.difference(en),
        isEmpty,
        reason: 'Keys present in Arabic but missing in English',
      );
    });

    test('no value is empty', () {
      for (final entry in enUs.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: 'en: ${entry.key}');
      }
      for (final entry in arEg.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: 'ar: ${entry.key}');
      }
    });

    test('interpolation placeholders stay identical across languages', () {
      // Guards against a translation dropping a {placeholder} used by the UI.
      final placeholder = RegExp(r'\{[^}]+\}');
      for (final key in enUs.keys) {
        final en =
            placeholder.allMatches(enUs[key]!).map((m) => m.group(0)).toList()
              ..sort();
        final ar =
            placeholder.allMatches(arEg[key]!).map((m) => m.group(0)).toList()
              ..sort();
        expect(ar, en, reason: 'placeholder mismatch for "$key"');
      }
    });
  });
}
