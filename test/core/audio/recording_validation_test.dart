import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskbite/core/audio/recording_validation.dart';

void main() {
  group('recording validation', () {
    final tempDir = Directory.systemTemp;

    test('returns missing when file does not exist', () {
      final path = '${tempDir.path}${Platform.pathSeparator}no_such_file.m4a';
      expect(
        classifyRecording(exists: false, lengthInBytes: 0, path: path),
        RecordingProblem.missing,
      );
    });

    test('returns empty when file is zero bytes', () {
      expect(
        classifyRecording(exists: true, lengthInBytes: 0, path: 'rec.m4a'),
        RecordingProblem.empty,
      );
    });

    test('returns unsupported for unknown extension', () {
      expect(
        classifyRecording(exists: true, lengthInBytes: 1024, path: 'rec.txt'),
        RecordingProblem.unsupportedFormat,
      );
    });

    test('returns too large when over max bytes', () {
      expect(
        classifyRecording(
          exists: true,
          lengthInBytes: kMaxAudioBytes + 1,
          path: 'rec.m4a',
        ),
        RecordingProblem.tooLarge,
      );
    });

    test('returns null for a valid supported recording', () {
      expect(
        classifyRecording(
          exists: true,
          lengthInBytes: kMaxAudioBytes - 1000,
          path: 'rec.m4a',
        ),
        null,
      );
    });

    test('audioExtensionOf normalizes case and handles paths', () {
      expect(audioExtensionOf('D:\\voice\\rec.M4A'), '.m4a');
      expect(audioExtensionOf('/tmp/rec.mp3'), '.mp3');
      expect(audioExtensionOf('rec'), '');
      expect(audioExtensionOf('rec.'), '');
    });
  });
}
