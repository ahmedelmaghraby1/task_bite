import 'package:flutter_test/flutter_test.dart';
import 'package:taskbite/core/audio/audio_level.dart';

void main() {
  group('audio_level', () {
    test('decibelsToLevel maps silence to 0 and 0dBFS to 1', () {
      expect(decibelsToLevel(-120), closeTo(0, 1e-6));
      expect(decibelsToLevel(-60), closeTo(0, 1e-6));
      expect(decibelsToLevel(-30), closeTo(0.5, 1e-6));
      expect(decibelsToLevel(0), closeTo(1.0, 1e-6));
    });

    test('decibelsToLevel clamps out of range', () {
      expect(decibelsToLevel(10), closeTo(1.0, 1e-6));
      expect(decibelsToLevel(-999), closeTo(0, 1e-6));
    });

    test('smoothLevel attacks rises and releases falls', () {
      const previous = 0.2;
      const target = 0.8;
      final up = smoothLevel(previous, target, attack: 1.0, release: 1.0);
      expect(up, closeTo(target, 1e-6));
      final down = smoothLevel(target, 0.2, attack: 1.0, release: 0.5);
      expect(down, closeTo(target + (0.2 - target) * 0.5, 1e-6));
    });

    test('decibelsToLinear follows a power curve', () {
      expect(decibelsToLinear(-20), closeTo(0.1, 1e-4));
      expect(decibelsToLinear(-60), closeTo(0, 1e-6));
      expect(decibelsToLinear(0), closeTo(1.0, 1e-6));
    });
  });
}
