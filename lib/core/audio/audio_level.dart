import 'dart:math' as math;

/// Converts a raw recorder amplitude into a 0.0–1.0 visualization level.
///
/// The `record` package reports amplitude in dBFS: `0` is full scale and
/// normal speech sits roughly between `-30` and `-5`. [floorDecibels] is the
/// magnitude of the floor that maps to silence, so `-floorDecibels` (and
/// anything quieter) reads as `0.0` and `0` reads as `1.0`.
///
/// This is a pure function so the mapping can be unit-tested without a
/// platform recorder.
double decibelsToLevel(double dbfs, {double floorDecibels = 60}) {
  if (dbfs.isNaN || dbfs.isInfinite || floorDecibels <= 0) return 0;
  final normalized = 1 + dbfs / floorDecibels;
  return normalized.clamp(0.0, 1.0);
}

/// Applies an attack/release smoothing curve to a live level so the waveform
/// follows speech quickly but decays gently instead of flickering.
///
/// [attack] controls how fast a rising level is followed, [release] how slowly
/// a falling level decays. Both are clamped to 0.0–1.0.
double smoothLevel(
  double previous,
  double next, {
  double attack = 0.7,
  double release = 0.35,
}) {
  final a = attack.clamp(0.0, 1.0);
  final r = release.clamp(0.0, 1.0);
  final target = next.clamp(0.0, 1.0);
  final current = previous.clamp(0.0, 1.0);
  return target >= current
      ? current + (target - current) * a
      : current + (target - current) * r;
}

/// Linear amplitude (0.0–1.0) from dBFS, matching the perceptual scale used by
/// many waveform widgets. Kept here next to [decibelsToLevel] for tests.
double decibelsToLinear(double dbfs) {
  if (dbfs.isNaN || dbfs.isInfinite) return 0;
  if (dbfs <= -60) return 0;
  return math.pow(10, dbfs / 20).toDouble().clamp(0.0, 1.0);
}
