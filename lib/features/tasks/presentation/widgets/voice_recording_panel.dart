import 'package:flutter/material.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/tasks/presentation/cubit/task_composer_cubit.dart';
import 'package:taskbite/features/tasks/presentation/widgets/waveform_bars.dart';

/// Live recording surface shown while the voice session is active.
///
/// The timer text comes from the cubit state (updated on every recorder tick)
/// and the waveform is fed the recorder's real amplitude via
/// [TaskComposerCubit.inputLevel]. When the platform cannot report amplitude a
/// clear fallback is shown instead of a fabricated animation.
class VoiceRecordingPanel extends StatelessWidget {
  const VoiceRecordingPanel({super.key, required this.cubit});

  final TaskComposerCubit cubit;

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final amplitudeAvailable = cubit.isAmplitudeAvailable;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusRow(
          color: scheme.error,
          labelKey: 'recognitionStatusListening',
          pulsing: true,
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            _formatDuration(cubit.state.recordingElapsed),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            height: 56,
            child:
                amplitudeAvailable
                    ? WaveformBars(
                      levelListenable: cubit.inputLevel,
                      color: scheme.primary,
                      height: 56,
                      barCount: 28,
                    )
                    : Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_off_rounded,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'recordingLevelUnavailableMessage'.tr(context),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 18),
        _Controls(cubit: cubit),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.color,
    required this.labelKey,
    required this.pulsing,
  });

  final Color color;
  final String labelKey;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          width: pulsing ? 12 : 8,
          height: pulsing ? 12 : 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          labelKey.tr(context),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.cubit});

  final TaskComposerCubit cubit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => cubit.cancelRecording(),
            icon: const Icon(Icons.close_rounded),
            label: Text('cancelRecording'.tr(context)),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.outlineVariant),
              padding: const EdgeInsetsDirectional.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => cubit.finishRecording(),
            icon: const Icon(Icons.send_rounded),
            label: Text('finishRecording'.tr(context)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
