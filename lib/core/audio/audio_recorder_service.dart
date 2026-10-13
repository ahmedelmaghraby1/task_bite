import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:taskbite/core/audio/audio_level.dart';

/// Why a recording session could not start.
enum AudioRecorderErrorKind { permissionDenied, startFailed }

/// Raised by [AudioRecorderService] when a session cannot be started.
class AudioRecorderException implements Exception {
  const AudioRecorderException(this.kind, this.message);

  final AudioRecorderErrorKind kind;
  final String message;

  @override
  String toString() => 'AudioRecorderException($kind): $message';
}

/// A finalized recording together with the facts needed to validate it.
class RecordedAudio {
  const RecordedAudio({
    required this.path,
    required this.duration,
    required this.sizeInBytes,
  });

  final String path;
  final Duration duration;
  final int sizeInBytes;
}

/// Records microphone audio to an app-private temporary file using the
/// `record` package.
///
/// The service owns three pieces of live state that the UI needs:
///
/// * [elapsed] – measured from the moment the recorder reported a successful
///   start (via a [Stopwatch], not a naive counter, so it cannot drift).
/// * [inputLevel] – a [ValueListenable] driven by the recorder's real
///   amplitude stream (dBFS normalized to 0.0–1.0). The waveform listens to
///   this directly so it never animates independently of the microphone.
/// * [isAmplitudeAvailable] – `false` when the platform cannot report
///   amplitude, so the UI can show an honest fallback instead of a fake wave.
///
/// A fresh instance is created per composer session (see `getIt`), and
/// [dispose] releases the platform recorder, the amplitude subscription and
/// the level notifier.
class AudioRecorderService {
  AudioRecorderService({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  final ValueNotifier<double> _inputLevel = ValueNotifier<double>(0);

  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Stopwatch _stopwatch = Stopwatch();
  String? _recordedFilePath;
  bool _isRecording = false;
  bool _isAmplitudeAvailable = true;
  Duration _elapsed = Duration.zero;
  bool _disposed = false;

  bool get isRecording => _isRecording;
  String? get recordedFilePath => _recordedFilePath;

  /// Time since the recorder successfully started the current session.
  Duration get elapsed => _elapsed;

  /// Live microphone level (0.0–1.0) for the waveform.
  ValueListenable<double> get inputLevel => _inputLevel;

  /// Whether amplitude monitoring is working on this platform/session.
  bool get isAmplitudeAvailable => _isAmplitudeAvailable;

  /// Requests (and checks) microphone permission.
  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (_) {
      return false;
    }
  }

  /// Starts a new session. Throws [AudioRecorderException] when the microphone
  /// is not permitted or the recorder cannot start. Duplicate calls are
  /// ignored so two sessions can never run at once.
  Future<void> startRecording() async {
    if (_isRecording) return;

    final allowed = await hasPermission();
    if (!allowed) {
      throw const AudioRecorderException(
        AudioRecorderErrorKind.permissionDenied,
        'Microphone permission was denied.',
      );
    }

    final path = await _generateFilePath();
    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
    } catch (error) {
      throw AudioRecorderException(
        AudioRecorderErrorKind.startFailed,
        'The recorder failed to start: $error',
      );
    }

    _recordedFilePath = path;
    _isRecording = true;
    _elapsed = Duration.zero;
    _stopwatch = Stopwatch()..start();
    _startAmplitudeMonitoring();
  }

  /// Stops the session, finalizes the file and returns it together with its
  /// measured duration and on-disk size. Returns `null` when nothing usable
  /// was produced.
  Future<RecordedAudio?> stopRecording() async {
    if (!_isRecording) return null;

    _stopwatch.stop();
    _elapsed = _stopwatch.elapsed;
    _isRecording = false;
    await _stopAmplitudeMonitoring();

    final path = await _recorder.stop();
    final resolved = path ?? _recordedFilePath;
    _recordedFilePath = resolved;
    if (resolved == null) return null;

    final file = File(resolved);
    final exists = await file.exists();
    final size = exists ? await file.length() : 0;
    return RecordedAudio(path: resolved, duration: _elapsed, sizeInBytes: size);
  }

  /// Aborts the session and deletes the partial file.
  Future<void> cancelRecording() async {
    _stopwatch.stop();
    _stopAmplitudeMonitoringSync();
    _isRecording = false;
    _elapsed = Duration.zero;
    _inputLevel.value = 0;
    try {
      if (await _recorder.isRecording()) {
        await _recorder.cancel();
      }
    } catch (_) {
      // Best effort – the file is removed below regardless.
    }
    await cleanUp();
  }

  /// Deletes the last finalized recording, if any.
  Future<void> cleanUp() async {
    final path = _recordedFilePath;
    _recordedFilePath = null;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A missing temp file is not an error worth surfacing.
    }
  }

  /// Releases the recorder and all monitoring resources.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _stopAmplitudeMonitoring();
    if (_isRecording) {
      try {
        await _recorder.cancel();
      } catch (_) {}
    }
    _isRecording = false;
    await _recorder.dispose();
    _inputLevel.dispose();
  }

  // ---- Internals ----------------------------------------------------------

  Future<String> _generateFilePath() async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return '${dir.path}${Platform.pathSeparator}voice_recording_$timestamp.m4a';
  }

  void _startAmplitudeMonitoring() {
    _isAmplitudeAvailable = true;
    _inputLevel.value = 0;
    _amplitudeSubscription?.cancel();
    try {
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen(
            (amplitude) {
              final raw = decibelsToLevel(amplitude.current);
              _inputLevel.value = smoothLevel(_inputLevel.value, raw);
            },
            onError: (_) {
              _isAmplitudeAvailable = false;
              _inputLevel.value = 0;
              _amplitudeSubscription?.cancel();
              _amplitudeSubscription = null;
            },
          );
    } catch (_) {
      _isAmplitudeAvailable = false;
    }
  }

  Future<void> _stopAmplitudeMonitoring() async {
    final subscription = _amplitudeSubscription;
    _amplitudeSubscription = null;
    await subscription?.cancel();
    if (!_disposed) _inputLevel.value = 0;
  }

  void _stopAmplitudeMonitoringSync() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    if (!_disposed) _inputLevel.value = 0;
  }
}
